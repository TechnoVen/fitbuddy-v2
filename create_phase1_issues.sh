#!/bin/bash

# Phase 1 GitHub Issues Creation Script
# Creates all Phase 1 issues for FitBuddy-v2

gh issue create --title "Phase 1.2: Exercise form - Dynamic fields UI" --body "**Task:** Update exercise form with dynamic fields based on exercise_type

**Implementation:**
- Modify app/views/workout_exercises/_form.html.erb
- Add exercise_type selector (strength, cardio, flexibility)
- Toggle fields based on selection:
  - Strength: sets, reps, weight_lbs
  - Cardio: duration_seconds
  - All: name, description, step_order, rest_seconds
- Use Stimulus JS for dynamic toggling
- Add field labels, placeholders, help text

**Files:** app/views/workout_exercises/_form.html.erb, app/javascript/controllers/exercise_form_controller.js
**Depends on:** #1 (Migration completed)
**Effort:** 4 hours
**Status:** Planned" --label "phase-1,exercise-validation,form"

gh issue create --title "Phase 1.3: AI Assist - Create AI service wrapper" --body "**Task:** Create AI service layer for consistent error handling and retries

**Implementation:**
- Create app/services/ai_service.rb
- Implement methods:
  - enhance_exercise(exercise, plan)
  - generate_plan(plan)
  - revise_plan(plan, messages)
- Add error handling and logging
- Implement exponential backoff retry logic (3 retries: 2s, 4s, 8s)
- Wrap RubyLLM calls with graceful error messages
- Queue failed requests for later retry

**Files:** app/services/ai_service.rb
**Depends on:** ruby_llm gem (already installed)
**Effort:** 6-8 hours
**Status:** Planned" --label "phase-1,ai-assist,services"

gh issue create --title "Phase 1.4: AI Assist - Real exercise enhancement" --body "**Task:** Replace placeholder AI assist with real AI suggestions

**Implementation:**
- Modify app/controllers/workout_exercises_controller.rb#update
- When ai_assist=1, call ai_service.enhance_exercise
- Build prompt with exercise details, user goal, plan level
- Handle response and show preview
- Add tracking fields: ai_suggestion_text, accepted_ai_suggestion

**Requirements:**
- Show side-by-side comparison (original vs suggested)
- Add Accept, Reject, Edit buttons
- Store accepted suggestions for analytics

**Files:** 
- app/controllers/workout_exercises_controller.rb
- app/views/workout_exercises/edit.html.erb
- db/migrate/XXXX_add_ai_suggestion_tracking.rb

**Depends on:** #3 (AI service), #2 (Exercise form)
**Effort:** 6-8 hours
**Status:** Planned" --label "phase-1,ai-assist,controller"

gh issue create --title "Phase 1.5: Workout Logging - Models and migrations" --body "**Task:** Create models and database schema for workout execution tracking

**Models to Create:**
- Workout (execution of a plan on a date)
  - belongs_to :workout_plan, :user
  - has_many :workout_logs
  - Fields: started_at, completed_at, notes, completion_percentage
  
- WorkoutLog (individual exercise execution)
  - belongs_to :workout, :workout_exercise
  - Fields: reps_completed, weight_used, duration_seconds, difficulty_rating (1-10), notes

**Implementation:**
- Create app/models/workout.rb and app/models/workout_log.rb
- Create migrations with proper foreign keys and indices
- Add validations and associations
- Calculate completion_percentage on Workout

**Files:** 
- app/models/workout.rb
- app/models/workout_log.rb
- db/migrate/XXXX_create_workouts.rb
- db/migrate/XXXX_create_workout_logs.rb

**Effort:** 3-4 hours
**Status:** Planned" --label "phase-1,workout-logging,models"

gh issue create --title "Phase 1.6: Workout Logging - Controllers and views" --body "**Task:** Create controllers and UI for workout execution

**Controllers:**
- WorkoutsController: new, create (start), show (active screen)
- WorkoutLogsController: create (log exercise)

**Views:**
- workouts/show.html.erb (main workout screen with)
  - Header (plan name, time elapsed)
  - Current exercise highlight
  - Progress bar
  - Timer display
  - Input form (reps/weight/duration/rating)
  - Checkboxes for completion

**JavaScript:**
- workout_timer_controller.js
  - Countdown timer
  - Audio alert for rest period end
  - Pause/resume controls

**Routes:**
- GET /workout_plans/:id/workouts/new
- POST /workout_plans/:id/workouts
- GET /workout_plans/:id/workouts/:id
- POST /workout_plans/:id/workouts/:id/workout_logs

**Files:**
- app/controllers/workouts_controller.rb
- app/controllers/workout_logs_controller.rb
- app/views/workouts/show.html.erb
- app/javascript/controllers/workout_timer_controller.js
- config/routes.rb

**Depends on:** #5 (Models)
**Effort:** 12-16 hours
**Status:** Planned" --label "phase-1,workout-logging,controller,views"

gh issue create --title "Phase 1.7: Onboarding - Create models and migrations" --body "**Task:** Create onboarding models and database schema

**Models:**
- PlanTemplate (predefined workout plan templates)
  - Fields: name, description, level, goal, duration_minutes, equipment (array), exercises_json
  
- Update User model:
  - Add onboarded (boolean, default: false)
  - Add fitness_level (enum: beginner, intermediate, advanced)
  - Add fitness_goal (enum: fat_loss, muscle_gain, endurance, flexibility, general)

**Migrations:**
- db/migrate/XXXX_create_plan_templates.rb
- db/migrate/XXXX_add_onboarding_to_users.rb

**Seed Data:**
- 5-10 realistic plan templates:
  - Beginner Fat Loss (30min, dumbbells)
  - Cardio Burn (20min, bodyweight)
  - Strength Builder (45min, barbell)
  - Flexibility (15min, yoga mat)
  - Full Body (35min, dumbbells + resistance bands)

**Effort:** 3-4 hours
**Status:** Planned" --label "phase-1,onboarding,models"

gh issue create --title "Phase 1.8: Onboarding - Create 4-step wizard UI" --body "**Task:** Create interactive onboarding flow

**Wizard Steps:**
1. Goal Selection (cards: Fat Loss, Muscle Gain, Endurance, Flexibility, General)
2. Experience Level (radio: Beginner, Intermediate, Advanced)
3. Time Commitment (slider: 15-120 minutes)
4. Equipment Available (checkboxes: Dumbbells, Barbell, Kettlebell, etc.)

**Implementation:**
- Create app/views/pages/onboarding.html.erb
- Create app/controllers/pages_controller.rb#onboarding and #complete_onboarding
- Use Stimulus JS for step management and validation
- Show progress indicator (1/4, 2/4, etc.)
- Add next/prev buttons, skip option

**After Completion:**
- Set user.onboarded = true
- Redirect to workout_plans with suggested templates
- Show 'Use Template' buttons

**Files:**
- app/views/pages/onboarding.html.erb
- app/javascript/controllers/onboarding_controller.js
- app/controllers/pages_controller.rb (update)

**Depends on:** #7 (Models)
**Effort:** 8-10 hours
**Status:** Planned" --label "phase-1,onboarding,views"

gh issue create --title "Phase 1.9: Onboarding - Integration with plan index" --body "**Task:** Integrate onboarding into main workflow

**Implementation:**
- Update WorkoutPlansController#index:
  - Redirect to onboarding if not onboarded
  - Show plan templates if no user plans
  - Add 'Use Template' button for each template
  
- Update workout_plans/_form to allow creating from template

**After Onboarding:**
- Show templates matching user's fitness_goal and fitness_level
- Allow copying template as starting point
- Modify field values before creating plan

**Files:**
- app/controllers/workout_plans_controller.rb (update)
- app/views/workout_plans/index.html.erb (update)
- db/seeds.rb (add plan template seed data)

**Depends on:** #8 (Wizard UI)
**Effort:** 4-6 hours
**Status:** Planned" --label "phase-1,onboarding,integration"

gh issue create --title "Phase 1.10: Testing - Write comprehensive tests for Phase 1" --body "**Task:** Create tests for all Phase 1 features

**Test Files:**
- test/models/workout_test.rb
- test/models/workout_log_test.rb
- test/controllers/workouts_controller_test.rb
- test/models/plan_template_test.rb
- test/controllers/pages_controller_test.rb
- test/controllers/workout_exercises_controller_test.rb (AI assist tests)

**Test Coverage:**
- Model validations (all models)
- Controller actions (authorization, logic)
- AI feature (mock OpenAI responses)
- Onboarding flow
- Workout logging flow
- Plan template usage

**System Tests:**
- E2E: sign up → onboarding → create plan from template → add exercises → start workout → log exercises

**Effort:** 8-10 hours
**Status:** Planned" --label "phase-1,testing"

echo "✅ Phase 1 GitHub issues created successfully!"
