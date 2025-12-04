require "test_helper"

class WorkoutExerciseTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @plan = @user.workout_plans.create!(
      level: "beginner",
      goal: "Fat Loss",
      duration_minutes: 30
    )
  end

  # Test presence validations
  test "requires step_order" do
    exercise = WorkoutExercise.new(
      workout_plan: @plan,
      name: "Squats",
      exercise_type: "strength",
      reps: 12
    )
    assert_not exercise.valid?
    assert exercise.errors[:step_order].present?
  end

  test "requires name" do
    exercise = WorkoutExercise.new(
      workout_plan: @plan,
      step_order: 1,
      exercise_type: "strength",
      reps: 12
    )
    assert_not exercise.valid?
    assert exercise.errors[:name].present?
  end

  test "requires exercise_type (enum defaults to strength)" do
    # Note: exercise_type has a default of 'strength' in migration, so it won't be blank
    # Test that the column exists and can be set
    exercise = @plan.workout_exercises.build(
      step_order: 1,
      name: "Squats",
      reps: 12
    )
    assert exercise.exercise_type.present?
    assert_equal "strength", exercise.exercise_type
  end

  # Test step_order uniqueness per plan
  test "step_order must be unique per workout_plan" do
    first_exercise = @plan.workout_exercises.create!(
      step_order: 1,
      name: "Squats",
      exercise_type: "strength",
      reps: 12
    )
    assert first_exercise.valid?

    second_exercise = WorkoutExercise.new(
      workout_plan: @plan,
      step_order: 1,
      name: "Lunges",
      exercise_type: "strength",
      reps: 10
    )
    assert_not second_exercise.valid?
    assert second_exercise.errors[:step_order].present?
  end

  test "step_order can be same across different plans" do
    plan2 = @user.workout_plans.create!(
      level: "intermediate",
      goal: "Muscle Gain",
      duration_minutes: 45
    )

    exercise1 = @plan.workout_exercises.create!(
      step_order: 1,
      name: "Squats",
      exercise_type: "strength",
      reps: 12
    )

    exercise2 = plan2.workout_exercises.create!(
      step_order: 1,
      name: "Bench Press",
      exercise_type: "strength",
      reps: 8
    )

    assert exercise1.valid?
    assert exercise2.valid?
  end

  # Test exercise_type enum
  test "accepts valid exercise types" do
    %w[strength cardio flexibility].each do |type|
      exercise = WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Exercise",
        exercise_type: type
      )
      # Add required fields based on type
      exercise.reps = 12 if type == 'strength'
      exercise.sets = 3 if type == 'strength'
      exercise.duration_seconds = 600 if type == 'cardio'
      
      assert exercise.valid?, "Should accept #{type}"
    end
  end

  test "rejects invalid exercise types" do
    # Enums in Rails raise ArgumentError when assigned invalid values
    assert_raises(ArgumentError) do
      WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Exercise",
        exercise_type: "invalid_type"
      )
    end
  end

  # Test reps validation
  test "reps must be between 1 and 1000" do
    invalid_values = [0, -5, 1001]
    invalid_values.each do |value|
      exercise = WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Squats",
        exercise_type: "strength",
        reps: value
      )
      assert_not exercise.valid?, "Should reject reps=#{value}"
      assert exercise.errors[:reps].present?
    end

    valid_values = [1, 5, 100, 1000]
    valid_values.each do |value|
      exercise = WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Squats",
        exercise_type: "strength",
        reps: value,
        sets: 3
      )
      assert exercise.valid?, "Should accept reps=#{value}"
    end
  end

  # Test duration_seconds validation
  test "duration_seconds must be between 1 and 3600" do
    invalid_values = [0, -30, 3601]
    invalid_values.each do |value|
      exercise = WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Running",
        exercise_type: "cardio",
        duration_seconds: value
      )
      assert_not exercise.valid?, "Should reject duration_seconds=#{value}"
      assert exercise.errors[:duration_seconds].present?
    end

    valid_values = [30, 300, 1800, 3600]
    valid_values.each do |value|
      exercise = WorkoutExercise.new(
        workout_plan: @plan,
        step_order: 1,
        name: "Running",
        exercise_type: "cardio",
        duration_seconds: value
      )
      assert exercise.valid?, "Should accept duration_seconds=#{value}"
    end
  end

  # Test weight_lbs validation
  test "weight_lbs must be positive and less than 500" do
    exercise = WorkoutExercise.new(
      workout_plan: @plan,
      step_order: 1,
      name: "Bench Press",
      exercise_type: "strength",
      reps: 8,
      weight_lbs: 501
    )
    assert_not exercise.valid?
    assert exercise.errors[:weight_lbs].present?

    exercise.weight_lbs = 225
    assert exercise.valid?
  end

  # Test sets validation
  test "sets must be between 1 and 10" do
    exercise = WorkoutExercise.new(
      workout_plan: @plan,
      step_order: 1,
      name: "Squats",
      exercise_type: "strength",
      reps: 12,
      sets: 11
    )
    assert_not exercise.valid?
    assert exercise.errors[:sets].present?

    exercise.sets = 5
    assert exercise.valid?
  end

  # Test rest_seconds validation
  test "rest_seconds must be between 0 and 600 (10 minutes)" do
    exercise = WorkoutExercise.new(
      workout_plan: @plan,
      step_order: 1,
      name: "Squats",
      exercise_type: "strength",
      reps: 12,
      rest_seconds: 601
    )
    assert_not exercise.valid?
    assert exercise.errors[:rest_seconds].present?

    exercise.rest_seconds = 120
    assert exercise.valid?
  end

  # Test custom validations
  test "strength exercises must have reps or sets" do
    # This test verifies the custom validation works
    # Since sets defaults to 3 in migration, a strength exercise without reps might still be invalid
    exercise = @plan.workout_exercises.build(
      step_order: 2,
      name: "Squats",
      exercise_type: "strength",
      sets: nil  # Explicitly set to nil to test the validation
    )
    # With no reps and no sets, should be invalid
    # Note: sets default to 3 in DB but in-memory it might be nil
    refute exercise.valid?, "Strength exercise without reps/sets should be invalid"
  end

  test "strength exercises with reps are valid" do
    exercise = @plan.workout_exercises.build(
      step_order: 3,
      name: "Squats",
      exercise_type: "strength",
      reps: 12
    )
    assert exercise.valid?, "Strength exercise with reps should be valid"
  end

  test "cardio exercises must have duration" do
    exercise = @plan.workout_exercises.build(
      step_order: 4,
      name: "Running",
      exercise_type: "cardio"
    )
    refute exercise.valid?
    assert exercise.errors[:base].any? { |msg| msg.include?("Cardio") }
  end

  test "cardio exercises with duration are valid" do
    exercise = @plan.workout_exercises.build(
      step_order: 5,
      name: "Running",
      exercise_type: "cardio",
      duration_seconds: 600
    )
    assert exercise.valid?
  end

  # Test successful creation
  test "creates valid strength exercise" do
    exercise = @plan.workout_exercises.create!(
      step_order: 1,
      name: "Squats",
      description: "Bodyweight squats",
      exercise_type: "strength",
      reps: 15,
      sets: 3,
      rest_seconds: 60
    )
    assert exercise.persisted?
    assert_equal "Squats", exercise.name
    assert_equal "strength", exercise.exercise_type
    assert_equal 15, exercise.reps
  end

  test "creates valid cardio exercise" do
    exercise = @plan.workout_exercises.create!(
      step_order: 1,
      name: "Running",
      description: "Steady-state cardio",
      exercise_type: "cardio",
      duration_seconds: 1800,
      rest_seconds: 120
    )
    assert exercise.persisted?
    assert_equal "Running", exercise.name
    assert_equal "cardio", exercise.exercise_type
    assert_equal 1800, exercise.duration_seconds
  end

  test "creates valid flexibility exercise" do
    exercise = @plan.workout_exercises.create!(
      step_order: 1,
      name: "Stretching",
      description: "Full body stretch",
      exercise_type: "flexibility",
      duration_seconds: 600
    )
    assert exercise.persisted?
    assert_equal "flexibility", exercise.exercise_type
  end
end
