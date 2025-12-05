require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test-user@example.com", password: "password123")
    @plan = WorkoutPlan.create!(goal: "general", duration_minutes: 30, level: "beginner", user: @user)
  end

  test "valid workout with required associations" do
    workout = Workout.new(workout_plan: @plan, user: @user, started_at: Time.current)
    assert workout.valid?
  end

  test "completion_percentage bounds" do
    workout = Workout.new(workout_plan: @plan, user: @user, completion_percentage: 50)
    assert workout.valid?

    workout.completion_percentage = -5
    assert_not workout.valid?

    workout.completion_percentage = 101
    assert_not workout.valid?
  end

  test "completed_at must be after started_at" do
    workout = Workout.new(workout_plan: @plan, user: @user, started_at: 1.hour.ago, completed_at: 2.hours.ago)
    assert_not workout.valid?
    assert_includes workout.errors[:completed_at], "must be after started_at"
  end
end
