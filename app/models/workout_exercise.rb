class WorkoutExercise < ApplicationRecord
  belongs_to :workout_plan

  # Enums
  enum exercise_type: { strength: 'strength', cardio: 'cardio', flexibility: 'flexibility' }

  # Validations
  validates :step_order, presence: true, numericality: { only_integer: true, greater_than: 0 },
                         uniqueness: { scope: :workout_plan_id }
  validates :name, presence: true
  validates :exercise_type, presence: true

  # Conditional validations based on exercise type
  validates :reps, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }, allow_nil: true
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 3600 },
                               allow_nil: true
  validates :sets, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :weight_lbs, numericality: { greater_than: 0, less_than_or_equal_to: 500 }, allow_nil: true
  validates :rest_seconds,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 600 }, allow_nil: true

  # Custom validations
  validate :strength_exercises_need_reps_or_sets
  validate :cardio_exercises_need_duration

  private

  def strength_exercises_need_reps_or_sets
    return unless strength? && reps.blank? && sets.blank?

    errors.add(:base, "Strength exercises must have either reps or sets defined")
  end

  def cardio_exercises_need_duration
    return unless cardio? && duration_seconds.blank?

    errors.add(:base, "Cardio exercises must have duration defined")
  end
end
