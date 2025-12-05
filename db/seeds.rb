puts "Cleaning database..."
WorkoutPlan.destroy_all
User.destroy_all

puts "Creating demo user..."
demo_user = User.create!(
  email: "demo@example.com",
  password: "password"
)

puts "Creating 5 workout plans..."

# Plan 1: Beginner Full Body Strength
plan1 = WorkoutPlan.create!(
  age: 28,
  height: 175,
  weight: 75,
  handicap: nil,
  level: "beginner",
  goal: "Full Body Strength",
  equipment: "Dumbbells, Resistance Bands",
  duration_minutes: 35,
  ai_plan: "Start with a 5-minute dynamic warm-up including arm circles and leg swings. Perform 3 sets of 10-12 reps for each exercise with 60 seconds rest between sets. Focus on proper form and controlled movements. Finish with 5 minutes of stretching.",
  user: demo_user
)

WorkoutExercise.create!(
  workout_plan: plan1,
  step_order: 1,
  name: "Goblet Squats",
  description: "Hold a dumbbell at chest level, squat down keeping your back straight and knees tracking over toes.",
  reps_or_duration: "12 reps",
  rest_seconds: 60
)

WorkoutExercise.create!(
  workout_plan: plan1,
  step_order: 2,
  name: "Dumbbell Chest Press",
  description: "Lie on bench or floor, press dumbbells from chest to full extension.",
  reps_or_duration: "10 reps",
  rest_seconds: 60
)

WorkoutExercise.create!(
  workout_plan: plan1,
  step_order: 3,
  name: "Bent-Over Rows",
  description: "Hinge at hips, pull dumbbells to lower chest, squeezing shoulder blades together.",
  reps_or_duration: "12 reps",
  rest_seconds: 60
)

# Plan 2: Intermediate Fat Loss
plan2 = WorkoutPlan.create!(
  age: 32,
  height: 168,
  weight: 68,
  handicap: "Lower back sensitivity",
  level: "intermediate",
  goal: "Fat Loss",
  equipment: "Kettlebells, Mat",
  duration_minutes: 40,
  ai_plan: "Begin with 5 minutes of light cardio warm-up. Perform circuit training with 45 seconds work, 15 seconds rest. Complete 4 rounds of the circuit. Focus on maintaining intensity throughout. Cool down with 5 minutes of stretching, paying special attention to lower back.",
  user: demo_user
)

WorkoutExercise.create!(
  workout_plan: plan2,
  step_order: 1,
  name: "Kettlebell Swings",
  description: "Hip-hinge movement, swing kettlebell to chest height using hip drive, not arms.",
  reps_or_duration: "45 seconds",
  rest_seconds: 15
)

WorkoutExercise.create!(
  workout_plan: plan2,
  step_order: 2,
  name: "Mountain Climbers",
  description: "In plank position, alternate bringing knees to chest in running motion.",
  reps_or_duration: "45 seconds",
  rest_seconds: 15
)

WorkoutExercise.create!(
  workout_plan: plan2,
  step_order: 3,
  name: "Kettlebell Goblet Squats",
  description: "Hold kettlebell at chest, squat down with controlled movement.",
  reps_or_duration: "45 seconds",
  rest_seconds: 15
)

# Plan 3: Advanced Powerlifting
plan3 = WorkoutPlan.create!(
  age: 25,
  height: 182,
  weight: 85,
  handicap: nil,
  level: "advanced",
  goal: "Strength & Power",
  equipment: "Barbell, Power Rack, Bench",
  duration_minutes: 60,
  ai_plan: "Warm up with 10 minutes of dynamic stretching and light sets. Perform 5 sets of 3-5 reps for main lifts with 3-4 minutes rest between sets. Focus on maximum strength development. Include accessory work for 3 sets of 8-10 reps. Finish with mobility work.",
  user: demo_user
)

WorkoutExercise.create!(
  workout_plan: plan3,
  step_order: 1,
  name: "Barbell Back Squat",
  description: "Full depth squat with barbell on upper back, maintaining neutral spine throughout.",
  reps_or_duration: "5 sets x 3 reps",
  rest_seconds: 240
)

WorkoutExercise.create!(
  workout_plan: plan3,
  step_order: 2,
  name: "Barbell Bench Press",
  description: "Lower bar to chest with control, press to full lockout.",
  reps_or_duration: "5 sets x 3 reps",
  rest_seconds: 240
)

WorkoutExercise.create!(
  workout_plan: plan3,
  step_order: 3,
  name: "Conventional Deadlift",
  description: "Hinge at hips, grip bar, drive through heels to stand tall with bar.",
  reps_or_duration: "5 sets x 3 reps",
  rest_seconds: 300
)

# Plan 4: Beginner Mobility & Flexibility
plan4 = WorkoutPlan.create!(
  age: 45,
  height: 160,
  weight: 62,
  handicap: "Knee arthritis",
  level: "beginner",
  goal: "Mobility & Flexibility",
  equipment: "Yoga Mat, Foam Roller",
  duration_minutes: 30,
  ai_plan: "Start with 5 minutes of gentle movement and breathing. Hold each stretch for 30-60 seconds, breathing deeply. Avoid putting excessive pressure on knees. Focus on gradual improvement in range of motion. End with 5 minutes of relaxation.",
  user: demo_user
)

WorkoutExercise.create!(
  workout_plan: plan4,
  step_order: 1,
  name: "Cat-Cow Stretch",
  description: "On hands and knees, alternate arching and rounding your back slowly.",
  reps_or_duration: "10 repetitions",
  rest_seconds: 0
)

WorkoutExercise.create!(
  workout_plan: plan4,
  step_order: 2,
  name: "Seated Forward Fold",
  description: "Sit with legs extended, gently fold forward reaching toward toes.",
  reps_or_duration: "Hold 60 seconds",
  rest_seconds: 30
)

WorkoutExercise.create!(
  workout_plan: plan4,
  step_order: 3,
  name: "Hip Flexor Stretch",
  description: "In lunge position, gently push hips forward to feel stretch in front hip.",
  reps_or_duration: "Hold 45 seconds each side",
  rest_seconds: 30
)

# Plan 5: Intermediate Muscle Building
plan5 = WorkoutPlan.create!(
  age: 30,
  height: 178,
  weight: 80,
  handicap: nil,
  level: "intermediate",
  goal: "Muscle Building",
  equipment: "Dumbbells, Barbell, Cable Machine",
  duration_minutes: 50,
  ai_plan: "Warm up with 5 minutes of light cardio and dynamic stretching. Perform 4 sets of 8-12 reps for each exercise with 90 seconds rest between sets. Focus on progressive overload and mind-muscle connection. Include both compound and isolation movements. Cool down with stretching.",
  user: demo_user
)

WorkoutExercise.create!(
  workout_plan: plan5,
  step_order: 1,
  name: "Barbell Rows",
  description: "Bent over, pull bar to lower chest, squeezing lats and rear delts.",
  reps_or_duration: "4 sets x 10 reps",
  rest_seconds: 90
)

WorkoutExercise.create!(
  workout_plan: plan5,
  step_order: 2,
  name: "Dumbbell Shoulder Press",
  description: "Press dumbbells overhead from shoulder height to full extension.",
  reps_or_duration: "4 sets x 10 reps",
  rest_seconds: 90
)

WorkoutExercise.create!(
  workout_plan: plan5,
  step_order: 3,
  name: "Barbell Bicep Curls",
  description: "Standing, curl bar from arms extended to full contraction.",
  reps_or_duration: "4 sets x 12 reps",
  rest_seconds: 90
)

WorkoutExercise.create!(
  workout_plan: plan5,
  step_order: 4,
  name: "Tricep Cable Extensions",
  description: "Using cable machine, extend arms downward, focusing on tricep contraction.",
  reps_or_duration: "4 sets x 12 reps",
  rest_seconds: 90
)

puts "Created user: #{demo_user.email}"
puts "Created #{demo_user.workout_plans.count} workout plans with #{WorkoutExercise.count} exercises"
puts "Done!"
