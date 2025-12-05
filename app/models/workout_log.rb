class WorkoutLog < ApplicationRecord
  belongs_to :workout
  belongs_to :workout_exercise, optional: true

  validates :workout, presence: true
  validates :reps, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight_lbs, numericality: { greater_than: 0 }, allow_nil: true

  scope :completed, -> { where(completed: true) }
end
