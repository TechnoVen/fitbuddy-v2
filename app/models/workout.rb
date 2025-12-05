class Workout < ApplicationRecord
  belongs_to :workout_plan
  belongs_to :user

  has_many :workout_logs, dependent: :destroy

  validates :workout_plan, presence: true
  validates :user, presence: true
  validates :completion_percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  validate :completed_at_after_started_at

  # Calculate completion percentage from associated workout_logs if available
  # Placeholder: actual implementation will depend on WorkoutLog structure
  def calculate_completion_percentage
    return completion_percentage if workout_logs.empty?

    # If workout_logs respond to completed flag / progress, implement accordingly.
    total = workout_logs.size
    done = workout_logs.select { |l| l.respond_to?(:completed) ? l.completed : false }.size
    ((done.to_f / total) * 100).to_i
  end

  private

  def completed_at_after_started_at
    return if completed_at.blank? || started_at.blank?

    if completed_at < started_at
      errors.add(:completed_at, "must be after started_at")
    end
  end
end
