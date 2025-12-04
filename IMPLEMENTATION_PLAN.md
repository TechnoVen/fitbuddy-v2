# FitBuddy-v2 Implementation Plan

**Repository:** `TechnoVen/fitbuddy-v2`  
**Status:** Ready for development  
**Last Updated:** December 4, 2025

---

## Overview

This document outlines the implementation roadmap to transform FitBuddyLite from a "workout planner" into a full "personal AI fitness coach" platform. All improvements are based on the deep business logic review in `BUSINESS_LOGIC_REVIEW.md`.

---

## Phase 1: Core Fixes & MVP Completion (Week 1)

### 1.1 Fix Exercise Validation & Data Model

**Objective:** Ensure exercise data integrity and better structure

**Changes:**

- Add uniqueness validation to `step_order` (scoped to workout_plan)
- Restructure exercise fields:
  - Replace `reps_or_duration` with separate `reps` (integer, optional) and `duration_seconds` (integer, optional)
  - Add `exercise_type` enum: strength, cardio, flexibility
  - Add `sets` (integer, default: 1)
  - Add `weight_lbs` (decimal, optional) for strength exercises
  - Add `notes` (text, optional)

**Files to Modify:**

- `db/migrate/XXXX_restructure_workout_exercises.rb` (new migration)
- `app/models/workout_exercise.rb` (validations)
- `app/views/workout_exercises/_form.html.erb` (dynamic form based on exercise_type)
- `test/models/workout_exercise_test.rb` (add validation tests)

**Migration Strategy:**

```ruby
# Backfill existing data:
# - Parse reps_or_duration to extract reps if numeric
# - Set duration_seconds to null for strength exercises
# - Default exercise_type to 'strength' for existing records
```

**Estimated Effort:** 4-6 hours

---

### 1.2 Implement Real AI Exercise Enhancement

**Objective:** Replace placeholder text with actual AI suggestions

**Changes:**

- Modify `WorkoutExercisesController#update` to call RubyLLM when `ai_assist=1`
- Build prompt: include exercise details, user goal, plan level, and new structure
- Show side-by-side comparison: original vs suggested
- Add `accepted_ai_suggestions` counter to track user engagement

**Files to Modify:**

- `app/controllers/workout_exercises_controller.rb` (real AI call with error handling)
- `app/views/workout_exercises/edit.html.erb` (add preview of AI suggestion)
- `db/migrate/XXXX_add_ai_suggestion_tracking.rb` (new field to WorkoutExercise)
- `app/models/workout_exercise.rb` (validate suggestion acceptance)

**Prompt Template:**

```
You are a personal fitness coach. Suggest improvements for this exercise:

Exercise: [name]
Type: [exercise_type] ([sets]x[reps/duration])
Current Description: [description]
Goal: [plan.goal]
User Level: [plan.level]
Duration Available: [plan.duration_minutes] min

Provide ONE specific, actionable improvement (1-2 sentences).
Focus on: form, safety, progression, or alignment with the user's goal.
```

**Estimated Effort:** 6-8 hours

---

### 1.3 Add Workout Execution / Logging MVP

**Objective:** Bridge planning and execution gap

**Models to Create:**

- `Workout` (execution of a WorkoutPlan on a specific date)
  - Fields: workout_plan_id, user_id, started_at, completed_at, notes
  - `has_many :workout_logs`
- `WorkoutLog` (record of individual exercise execution)
  - Fields: workout_id, workout_exercise_id, reps_completed, weight_used, duration_seconds, notes, difficulty_rating
  - Tracks actual performance vs planned

**Controllers:**

- `WorkoutsController`: new, create (start workout), show (active workout screen)
- `WorkoutLogsController`: create (log individual exercise)

**Views:**

- `workouts/show.html.erb`:
  - Full screen workout UI with timer
  - List of exercises with checkboxes
  - Timer for rest periods
  - Quick input for reps/weight/duration
  - Submit button to complete

**Routes:**

```ruby
resources :workout_plans do
  resources :workouts, only: [:new, :create, :show] do
    resources :workout_logs, only: [:create]
  end
end
```

**Features:**

- Auto-play timer for rest periods (audio notification)
- Show all 5 upcoming exercises (not just current)
- Option to modify plan mid-workout (skip exercise, repeat set)
- Show completed % at top

**Estimated Effort:** 12-16 hours

---

### 1.4 Improve Onboarding Flow

**Objective:** Reduce first-time user drop-off

**Changes:**

- Create `PagesController#onboarding` route
- Build 4-step wizard:
  1. What's your fitness goal? (cards: Fat Loss, Muscle Gain, Endurance, Flexibility, Weight Loss, Cardio)
  2. What's your experience level? (radio: Beginner, Intermediate, Advanced)
  3. How much time can you dedicate? (slider: 15-120 minutes)
  4. Do you have equipment? (checkboxes: Dumbbells, Barbell, Kettlebell, Resistance Bands, Treadmill, Yoga Mat, None)
- After onboarding, show plan template suggestions
- Create `PlanTemplate` model with seed data for common plans

**Files:**

- `db/migrate/XXXX_create_plan_templates.rb`
- `app/models/plan_template.rb`
- `app/models/user.rb` (add `onboarded` boolean, `fitness_level`, `fitness_goal`)
- `app/controllers/pages_controller.rb` (onboarding action)
- `app/views/pages/onboarding.html.erb`
- `app/views/workout_plans/index.html.erb` (show templates if no plans)

**Estimated Effort:** 8-10 hours

---

## Phase 2: AI & Conversation Improvements (Week 2)

### 2.1 Multi-Chat Architecture

**Objective:** Organize conversations by topic/focus area

**Changes:**

- Modify `Chat` model:
  - Add `topic` field (string, user-defined or AI-suggested)
  - Add `focus_area` enum: general, leg_day, upper_body, cardio, form_review, progression, nutrition
  - Add `message_count` counter cache
  - Add `summary` (AI-generated summary of chat key points)
- Update routes to handle multiple chats per plan
- Create chat browser UI on plan show page

**Files:**

- `db/migrate/XXXX_enhance_chats_model.rb`
- `app/models/chat.rb` (add fields, validations)
- `app/controllers/chats_controller.rb` (index action to list all chats)
- `app/views/workout_plans/show.html.erb` (chat switcher)
- `app/views/chats/index.html.erb` (new)

**Features:**

- UI to create new chat with topic
- Show chat list with preview (first message + count)
- Auto-suggest topics based on workout plan
- Generate quick summaries of old chats

**Estimated Effort:** 6-8 hours

---

### 2.2 Integrate Plan Revision into Main Flow

**Objective:** Make AI plan refinement a first-class feature

**Changes:**

- Add "Revise Plan" button prominently on plan show page (not hidden in chat)
- Show before/after comparison of plan revisions
- Track revision history: show how plan changed over time
- Allow user to accept/reject/edit revisions before saving

**Files:**

- `db/migrate/XXXX_add_plan_revisions_tracking.rb` (add revision table)
- `app/models/plan_revision.rb` (new model)
- `app/models/workout_plan.rb` (has_many :plan_revisions)
- `app/controllers/workout_plans_controller.rb` (revise action)
- `app/views/workout_plans/show.html.erb` (add Revise button, show revision history)

**Estimated Effort:** 6-8 hours

---

### 2.3 Equipment Model & Validation

**Objective:** Structured equipment tracking and consistency

**Changes:**

- Create `Equipment` model with predefined options
- Update `WorkoutPlan` to use has_and_belongs_to_many :equipment
- Validate that exercises don't require equipment not in plan
- Add equipment filter to plan listing

**Files:**

- `db/migrate/XXXX_create_equipment_model.rb`
- `db/migrate/XXXX_create_join_table_workout_plans_equipment.rb`
- `app/models/equipment.rb` (new)
- `app/models/workout_plan.rb` (has_and_belongs_to_many)
- `app/models/workout_exercise.rb` (validate equipment)
- `app/controllers/workout_plans_controller.rb` (add equipment selector)
- `app/views/workout_plans/_form.html.erb` (equipment checkboxes)
- `db/seeds.rb` (add equipment seed data)

**Equipment Options:**

- Dumbbells, Barbell, Kettlebell, Resistance Bands
- Treadmill, Stationary Bike, Rowing Machine
- Pull-up Bar, Yoga Mat, Medicine Ball
- Cable Machine, Smith Machine

**Estimated Effort:** 5-6 hours

---

### 2.4 AI Error Recovery & Retry Logic

**Objective:** Graceful failure and automatic recovery

**Changes:**

- Implement exponential backoff retry for AI calls
- Create `AiRequest` model to queue failed requests
- Add background job (Sidekiq) for async retry
- Show user-friendly error messages based on error type

**Files:**

- `db/migrate/XXXX_create_ai_requests.rb`
- `app/models/ai_request.rb` (new)
- `app/jobs/retry_ai_request_job.rb` (new background job)
- `app/services/ai_service.rb` (wrapper around RubyLLM with retry logic)
- `app/controllers/ai_messages_controller.rb` (use AI service)
- `app/controllers/workout_plans_controller.rb` (use AI service)

**Error Handling:**

- Rate limited (429) → Retry in 30s, show "trying again..."
- Invalid API key → Alert admin, show "setup error"
- Timeout → Retry up to 3 times with backoff
- Other → Log, show generic message, queue for manual review

**Estimated Effort:** 8-10 hours

---

## Phase 3: Analytics & Engagement (Week 3)

### 3.1 Progress Tracking & Metrics

**Objective:** Show users their fitness gains

**Changes:**

- Add `WorkoutStats` model to aggregate user data:
  - Total workouts completed
  - Total exercises completed
  - Average plan adherence %
  - Exercises with increasing weight/reps trend
- Create dashboard view showing:
  - This week's workouts
  - 4-week trend chart
  - "Personal records" (heaviest weight, most reps)
  - Streak (consecutive days with workout)

**Files:**

- `db/migrate/XXXX_create_workout_stats.rb`
- `app/models/user.rb` (has_one :workout_stats)
- `app/models/workout_stats.rb` (calculations)
- `app/controllers/dashboards_controller.rb` (new)
- `app/views/dashboards/show.html.erb` (new)
- Add charts with Chart.js or similar

**Estimated Effort:** 10-12 hours

---

### 3.2 Plan Sharing & Discovery

**Objective:** Enable community and network effects

**Changes:**

- Add `visibility` enum to WorkoutPlan: private, shared, public
- Add `Plan` model (published plans users can discover)
- Copy functionality: "Use this plan" → creates private copy in user's account
- Rating/review system on plans
- Filtering: sort by rating, difficulty, duration

**Files:**

- `db/migrate/XXXX_add_visibility_to_plans.rb`
- `app/models/plan.rb` (published plans)
- `app/models/plan_copy.rb` (track which users used which plans)
- `app/controllers/plans_controller.rb` (browse, copy)
- `app/views/plans/index.html.erb` (plan marketplace)

**Estimated Effort:** 12-14 hours

---

### 3.3 Progression Strategy & Auto-Adjustment

**Objective:** Built-in progression for continuous gains

**Changes:**

- Add `progression_strategy` enum to WorkoutPlan:
  - linear (increase 5% weight each week)
  - periodized (high volume → low volume → power week)
  - escalating_density (more reps/weight in less time)
- AI recommendation: "You're ready to increase weight" based on completion %
- Auto-adjust exercises: if user completes all reps 3x in a row, suggest increase

**Files:**

- `db/migrate/XXXX_add_progression_to_plans.rb`
- `app/services/progression_calculator.rb` (AI recommendations)
- `app/models/workout_plan.rb` (progression logic)
- `app/views/chats/show.html.erb` (show progression suggestions in chat)

**Estimated Effort:** 8-10 hours

---

## Implementation Priority Matrix

| Phase | Feature             | Priority | Effort | User Impact | Dependencies |
| ----- | ------------------- | -------- | ------ | ----------- | ------------ |
| 1.1   | Exercise Validation | HIGH     | 4-6h   | Medium      | None         |
| 1.2   | Real AI Assist      | HIGH     | 6-8h   | High        | 1.1          |
| 1.3   | Workout Logging     | CRITICAL | 12-16h | Very High   | None         |
| 1.4   | Onboarding          | HIGH     | 8-10h  | High        | None         |
| 2.1   | Multi-Chat          | MEDIUM   | 6-8h   | Medium      | None         |
| 2.2   | Plan Revision UI    | MEDIUM   | 6-8h   | Medium      | None         |
| 2.3   | Equipment Model     | MEDIUM   | 5-6h   | Low         | None         |
| 2.4   | Error Recovery      | HIGH     | 8-10h  | Medium      | None         |
| 3.1   | Progress Tracking   | HIGH     | 10-12h | High        | 1.3          |
| 3.2   | Plan Sharing        | MEDIUM   | 12-14h | High        | None         |
| 3.3   | Progression         | MEDIUM   | 8-10h  | High        | 3.1          |

---

## Development Workflow

### Git Branches

```bash
# For each major feature:
git checkout -b feature/workout-logging
git checkout -b feature/exercise-validation
git checkout -b feature/ai-error-recovery
# etc.

# Commit frequently with descriptive messages
git commit -m "Feat: Add WorkoutLog model with execution tracking"
```

### Testing Strategy

- Unit tests for all model validations
- Integration tests for AI workflows
- System tests for critical user flows (create plan → log workout → see progress)

### Code Review

- Self-review before committing (read changes carefully)
- Use `git diff` to spot issues
- Test in browser before committing

---

## Deployment Considerations

### Database Migrations

- Test migrations on local copy first
- Backfill data carefully (see migration strategies above)
- No destructive changes without data backup

### API Changes

- OpenAI rate limiting (implement quota tracking)
- Monitor API costs (log all requests)
- Fallback for API downtime

### Performance

- Index database queries that filter by user_id, workout_plan_id, created_at
- Cache frequently accessed data (equipment options, plan templates)
- Lazy-load chat history (pagination)

---

## Success Metrics

After implementing all phases, measure:

| Metric              | Target                                  | How to Track                 |
| ------------------- | --------------------------------------- | ---------------------------- |
| **Activation**      | 80% users create plan within week 1     | Segment users by signup date |
| **First Execution** | 60% users log 1st workout within week 2 | Workouts table growth        |
| **Engagement**      | 40% DAU logging workouts                | Daily active users           |
| **Retention**       | 50% users return after 1 month          | Cohort analysis              |
| **AI Trust**        | 60% users use AI enhance at least once  | Feature adoption tracking    |
| **Progression**     | 30% users see weight/reps increase      | Aggregate WorkoutLog data    |

---

## Risk Mitigation

| Risk                        | Mitigation                                                  |
| --------------------------- | ----------------------------------------------------------- |
| AI API costs spike          | Implement quota, show usage to user, warn before overage    |
| Complex data migration      | Test on backup, rollback plan, phased rollout               |
| Performance degrades        | Add database indexes incrementally, monitor slow queries    |
| User confusion on new flows | User testing with 5-10 people, iterate UI based on feedback |
| Third-party API changes     | Pin gem versions, monitor deprecation warnings              |

---

## Next Steps

1. **Review this plan** with team if applicable
2. **Create GitHub issues** for each feature (use this doc as issue templates)
3. **Start Phase 1.1:** Exercise validation (lowest risk, enables others)
4. **Move sequentially** through Phase 1, then Phase 2, then Phase 3
5. **Ship incrementally:** Deploy Phase 1 to production before starting Phase 2

---

## Questions to Answer Before Starting

1. **Do you want AI features behind a paywall later?** (affects how we track usage)
2. **Should we add wearables integration** (Apple HealthKit, Fitbit) in Phase 3?
3. **Any team members to coordinate with?** (you're working independently on fitbuddy-v2)
4. **Deployment environment?** (Heroku, AWS, DigitalOcean, etc.)
5. **Timeline pressure?** (affects prioritization and parallelization)

---

## Document Versions

| Version | Date        | Author       | Changes                                     |
| ------- | ----------- | ------------ | ------------------------------------------- |
| 1.0     | Dec 4, 2025 | AI Assistant | Initial plan based on business logic review |
