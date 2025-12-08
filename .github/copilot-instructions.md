# FitBuddy AI Coding Agent Instructions

## Architecture Overview

**FitBuddy** is a Rails 7 AI-powered fitness coach application that generates personalized workout plans. The architecture centers around **AI-first workflows** where user interactions trigger LLM-based plan generation and revision.

### Core Data Flow
```
User → Chat/WorkoutPlan → AIService → RubyLLM (OpenAI) → Structured Response → DB + UI
```

**Key architectural decisions:**
- **All AI calls MUST go through `AIService`** (`app/services/ai_service.rb`) — never call `RubyLLM` directly
- AI responses follow a structured format: `SUGGESTIONS:` and `UPDATES:` sections parsed by `AIService#extract_section`
- System prompt is centralized in `config/ai.yml` and injected via `with_instructions(AIConfig.system_prompt)` when the LLM client supports it
- Plan revisions use a **preview + apply** pattern: `revise_plan` generates preview, `apply_revision` commits changes

## Critical Workflows

### Running Tests
```bash
bin/rails test -v                    # Run all tests with verbose output
bin/rails test test/models/          # Run model tests only
bin/rails ai:audit                   # Check for direct RubyLLM usage (should return clean)
```

**Test patterns:** Uses Minitest (not RSpec). Fixtures loaded automatically. Tests run in parallel by default (`test/test_helper.rb`).

### Database Setup
```bash
bin/rails db:create db:migrate db:seed   # Initial setup
bin/rails db:drop db:create db:migrate   # Full reset
```

**Demo credentials:** `demo@example.com` / `password` (from `db/seeds.rb`)

### AI Development
```bash
# Set API key in .env or Rails credentials
OPENAI_API_KEY=sk-...

# To avoid real API calls during development, AIService has retry logic with exponential backoff (2s, 4s, 8s)
# Check logs: tail -f log/development.log
```

## Project-Specific Conventions

### AI Integration Pattern
**All controllers use this pattern:**
```ruby
# In controllers
ai_service = AIService.new
result = ai_service.chat(prompt)          # For chat messages
result = ai_service.generate_plan(plan)   # For plan generation
result = ai_service.revise_plan(plan, messages)  # For plan revision
```

**Never do this:**
```ruby
RubyLLM::Client.new.chat(...)  # ❌ Bypasses centralized logic, retry, logging
```

### Model Validations (WorkoutExercise)
- `step_order` must be unique **per workout_plan** (not globally)
- Exercise types: `strength`, `cardio`, `flexibility` (enum)
- Strength exercises require `reps` OR `sets`; cardio requires `duration_seconds`
- See `test/models/workout_exercise_test.rb` for 19 comprehensive validation tests

### Routes Structure
```ruby
# Nested routes pattern
resources :workout_plans do
  resources :chats, only: [:show, :create] do
    post 'revise_plan', on: :member       # Generates preview
    post 'apply_revision', on: :member    # Commits changes
    resources :ai_messages, only: [:create]
  end
  resources :workout_exercises, except: [:index, :show]
  resources :workouts do
    resources :workout_logs
  end
end
```

### Frontend (Turbo + Stimulus)
- **Turbo Frames** for inline updates: `plan_revision_preview` frame loads diff before applying
- **Stimulus controllers:**
  - `theme_controller.js`: toggles `data-theme` attribute on `<html>`, persists to localStorage
  - `diff_highlight_controller.js`: highlights changed fields in plan revision preview
- Assets require **server restart + hard refresh (Cmd+Shift+R)** to load in dev

### Theme System
- CSS variables in `app/assets/stylesheets/themes/_halfmoon.scss`
- Light/dark theme via `html[data-theme="light|dark"]`
- Button styles in `app/assets/stylesheets/components/_buttons.scss`

## Integration Points

### AIService Responsibilities
- Retry logic with exponential backoff (3 attempts)
- Error handling: `AIServiceError`, `RateLimitError`, `TimeoutError`
- Prompt building: `build_plan_generation_prompt`, `build_plan_revision_prompt`, `build_exercise_enhancement_prompt`
- Response parsing: `parse_plan_generation_response`, `parse_plan_revision_response`
- Uses `with_instructions` when client supports it, falls back to system message in array

### External Dependencies
- **RubyLLM gem** (v1.9.1): wrapper for OpenAI API
- **Devise** for authentication
- **Bootstrap** + custom SCSS for styling
- **PostgreSQL** (required, not SQLite)

## Key Files Reference

| Pattern | File | Purpose |
|---------|------|---------|
| AI calls | `app/services/ai_service.rb` | Central LLM wrapper with retry/backoff |
| AI config | `config/ai.yml` | System prompt and AI behavior rules |
| Routes | `config/routes.rb` | Nested resources for plans/chats/exercises |
| Validations | `test/models/workout_exercise_test.rb` | 19 tests (59 assertions) covering all validation rules |
| Seeds | `db/seeds.rb` | Demo user + 2 sample plans with exercises |
| Chats | `app/controllers/chats_controller.rb` | Preview/apply pattern for plan revisions |

## Common Pitfalls

1. **Don't bypass AIService** — use `bin/rails ai:audit` to detect violations
2. **step_order uniqueness** is scoped to workout_plan_id, not global
3. **System prompt duplication** — when using `with_instructions`, don't also add system prompt to messages array
4. **Frontend assets** — new Stimulus controllers or SCSS changes won't load without server restart
5. **Test database** — uses fixtures from `test/fixtures/`, auto-loaded by `test/test_helper.rb`

## Implementation Plan Reference

See `IMPLEMENTATION_PLAN.md` for the full Phase 1-3 roadmap. Key phases:
- **Phase 1** (completed): Exercise validations, real AI enhancement, workout logging MVP
- **Phase 2** (planned): Onboarding flow, plan templates, multi-chat
- **Phase 3** (planned): Progress tracking, social features, wearable integration

## Current Branch

**Branch:** `feature/phase-1.3-ai-service`  
**Status:** Active development — AI centralization, homepage redesign, theme system  
**Recent work:** Plan revision preview (Turbo Frame), theme toggle (Stimulus), Halfmoon-inspired UI

Run `TODO.md` for current task list and resume checklist.
