# Project TODOs (persisted)

- Repository: `TechnoVen/fitbuddy-v2`
- Branch: `feature/phase-1.3-ai-service`
- Last saved: 2025-12-09
- Latest action: Added Copilot instructions, AI audit task, completed theme system (2025-12-09)

## Purpose

This file is the single source-of-truth for the assistant-managed TODOs. Use it as the memory snapshot for where we left off — the assistant will update it before ending each session so we can resume quickly later.

## Quick status (what's done) ✅

- **Plan revision preview + apply flow** (Turbo Frame + Stimulus) — implemented and tested (`app/controllers/chats_controller.rb`, `app/views/chats/revise_plan_preview.html.erb`).
- **AIService centralization** — AI calls moved to `app/services/ai_service.rb`. All controllers use `ai_service.chat()` pattern. Tests passing.
- **AI audit task** — added `lib/tasks/ai_audit.rake` to detect direct RubyLLM usage. Run with `bin/rails ai:audit`.
- **Copilot instructions** — comprehensive guide at `.github/copilot-instructions.md` documenting architecture, workflows, conventions, and pitfalls.
- **Homepage redesign** — Halfmoon-inspired two-column layout at `app/views/pages/home.html.erb` (left: app info, right: demo chat panel).
- **Theme system** — light/dark theme toggle with CSS variables (`app/assets/stylesheets/themes/_halfmoon.scss`), Stimulus controller (`theme_controller.js`), and button styles (`components/_buttons.scss`).
- **Navbar updates** — wired to real routes (Home, Plans, Create Plan) with theme toggle button and conditional sign-in/sign-up links.
- **Fixed bugs** — resolved `pages_home_path` error (replaced with `root_path`).
- **Persisted TODO file** — this file kept up to date throughout development.
- **All changes pushed** to `origin/feature/phase-1.3-ai-service`.

## Next Priority Tasks 🎯

### High Priority (Start Here)

1. **Polish Homepage & Theme Components**
   - Add responsive breakpoints and mobile-first styles
   - Create form components (inputs, textareas, selects) in Halfmoon style
   - Add modal/dialog patterns if needed
   - Ensure accessibility (ARIA labels, keyboard navigation)
   - Test on mobile devices
   - **Files:** `app/assets/stylesheets/themes/_halfmoon.scss`, `components/_forms.scss` (new)

2. **Improve AI System Prompt**
   - Expand `config/ai.yml` with more specific persona guidelines
   - Add safety rules and edge-case handling
   - Document structured output formats (JSON schemas)
   - Test prompt variations with real API calls
   - **Files:** `config/ai.yml`, `test/services/ai_service_test.rb`

3. **Run Full Test Suite & Fix Issues**
   - Execute `bin/rails test -v` and address any failures
   - Add missing controller tests for new features (theme, homepage, chat revisions)
   - Test AI service error handling paths
   - **Files:** `test/controllers/*_test.rb`, `test/services/ai_service_test.rb`

### Medium Priority

4. **WorkoutExercise Validations**
   - Review existing validations in `app/models/workout_exercise.rb`
   - Ensure `step_order` uniqueness per plan is enforced
   - Add boundary tests for numeric fields
   - **Status:** Most validations exist; needs review and possibly tightening

5. **Dynamic Exercise Form UI**
   - Create `exercise_form_controller.js` Stimulus controller
   - Add conditional field visibility based on exercise type
   - Enable add/remove exercise rows dynamically
   - **Files:** `app/javascript/controllers/exercise_form_controller.js`, `app/views/workout_exercises/_form.html.erb`

6. **Workout Execution & Logging MVP**
   - Implement `Workout` and `WorkoutLog` models (already scaffolded)
   - Create controllers and views for workout execution flow
   - Add UI to start workout, log exercises, and mark complete
   - **Files:** `app/models/workout.rb`, `app/models/workout_log.rb`, `app/controllers/workouts_controller.rb`

### Lower Priority / Future

7. **AI-Powered Workout Generator**
   - Create `WorkoutGeneratorService` that takes user preferences
   - Add user profile fields (age, fitness level, goals, equipment)
   - Build UI for preference collection
   - **Effort:** Large feature, requires design & iteration

8. **Monitoring & Rate Limiting**
   - Track AI API usage per user
   - Add rate limits and quota enforcement
   - Create admin dashboard for cost monitoring
   - **Dependencies:** Requires Redis or similar for rate limiting

9. **Onboarding Flow & Templates**
   - Create `PlanTemplate` model with seed data
   - Build multi-step onboarding wizard
   - Allow users to start from template or create custom
   - **Files:** New migrations, models, controllers, views

10. **Equipment Model & Validation**
    - Create `Equipment` model and join table
    - Validate plans against user's available equipment
    - Suggest alternatives when equipment is missing
    - **Files:** New migrations, `app/models/equipment.rb`

## Blockers & Notes

- Frontend assets (new Stimulus controllers and SCSS) require a dev server restart and full browser refresh to load in development. If you see missing behavior, restart server and clear cache.
- Some AI behavior changes require coordinated deployment and API key configuration in production (check `ENV` and `config/credentials`).

## How to resume tomorrow (quick checklist)

1. Pull latest branch & ensure clean working directory:

```bash
git checkout feature/phase-1.3-ai-service
git pull origin feature/phase-1.3-ai-service
```

2. Run tests (confirm green):

```bash
bin/rails test -v
```

3. Start dev server and open the homepage to sanity-check UI & theme toggle:

```bash
bin/rails server
# open http://localhost:3000 and hard refresh (Cmd+Shift+R)
```

4. If continuing on AI stabilization: run a grep for direct RubyLLM usage and review `AIService` coverage:

```bash
git grep "RubyLLM" || true
git grep "Rubyllm" || true
git grep "with_instructions" || true
```

5. If continuing UI work: run a quick smoke check of the homepage and chat pages; open DevTools for style/JS errors.

## Key Files & Reference 📚

| Category | Files | Purpose |
|----------|-------|---------|
| **AI Integration** | `app/services/ai_service.rb` | Central LLM wrapper with retry logic |
| | `config/ai.yml` | System prompt configuration |
| | `lib/tasks/ai_audit.rake` | Audit task to detect direct RubyLLM usage |
| **Theme & UI** | `app/assets/stylesheets/themes/_halfmoon.scss` | CSS variables for light/dark theme |
| | `app/assets/stylesheets/components/_buttons.scss` | Button styles |
| | `app/javascript/controllers/theme_controller.js` | Theme toggle Stimulus controller |
| **Views** | `app/views/pages/home.html.erb` | Halfmoon-inspired homepage |
| | `app/views/layouts/application.html.erb` | Main layout with navbar |
| | `app/views/chats/revise_plan_preview.html.erb` | Plan revision preview |
| **Controllers** | `app/controllers/chats_controller.rb` | Chat & plan revision logic |
| | `app/controllers/workout_plans_controller.rb` | Plan CRUD |
| **Tests** | `test/models/workout_exercise_test.rb` | 19 comprehensive validation tests |
| | `test/services/ai_service_test.rb` | AI service unit tests |
| **Docs** | `.github/copilot-instructions.md` | Comprehensive AI agent guide |
| | `TODO.md` | This file (persistent task tracking) |
| | `IMPLEMENTATION_PLAN.md` | Full Phase 1-3 roadmap |

## Git & Workflow Notes 🔧

**Current branch:** `feature/phase-1.3-ai-service`  
**Remote:** `origin` = `https://github.com/TechnoVen/fitbuddy-v2.git`

**Common commands:**
```bash
# Development
bin/rails server                    # Start dev server
bin/rails test -v                   # Run all tests
bin/rails ai:audit                  # Check for direct RubyLLM usage
tail -f log/development.log         # Monitor logs

# Database
bin/rails db:migrate                # Run migrations
bin/rails db:seed                   # Load demo data (demo@example.com / password)
bin/rails db:reset                  # Drop, create, migrate, seed

# Git
git status                          # Check working directory
git add -A && git commit -m "..."   # Stage and commit
git push origin feature/phase-1.3-ai-service  # Push to remote
```

## Known Issues & Gotchas ⚠️

1. **Frontend assets caching** — New Stimulus controllers or SCSS changes require:
   - Stop the Rails server
   - Restart: `bin/rails server`
   - Hard refresh browser: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)

2. **Theme toggle visibility** — The theme toggle button may not appear immediately; verify:
   - `theme_controller.js` is loaded (check browser DevTools → Sources)
   - Button has `data-controller="theme"` and `data-action="click->theme#toggle"`

3. **AI API rate limits** — `AIService` has built-in retry with exponential backoff (2s, 4s, 8s). Set `OPENAI_API_KEY` in `.env` or Rails credentials.

4. **Test database** — Uses fixtures from `test/fixtures/`. Auto-loaded by `test/test_helper.rb`. Tests run in parallel by default.

5. **step_order uniqueness** — Scoped to `workout_plan_id`, not globally unique. See validation tests.

## Resume Checklist (Next Session) ✨

When you return to this project:

1. **Pull latest changes:**
   ```bash
   git checkout feature/phase-1.3-ai-service
   git pull origin feature/phase-1.3-ai-service
   ```

2. **Verify environment:**
   ```bash
   bundle install                   # Update gems if needed
   bin/rails db:migrate             # Run any new migrations
   ```

3. **Run tests:**
   ```bash
   bin/rails test -v                # Should see 37 runs, 111 assertions, 0 failures
   ```

4. **Start server & verify UI:**
   ```bash
   bin/rails server
   # Open http://localhost:3000
   # Test theme toggle (button in navbar)
   # Try demo login: demo@example.com / password
   ```

5. **Review this file** — Check "Next Priority Tasks" section above for what to work on next.

---

**Last updated:** 2025-12-09  
**Status:** Ready for next development session  
**Branch state:** All changes committed and pushed to `origin/feature/phase-1.3-ai-service`
