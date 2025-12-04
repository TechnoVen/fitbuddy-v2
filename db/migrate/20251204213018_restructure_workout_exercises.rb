class RestructureWorkoutExercises < ActiveRecord::Migration[7.1]
  def up
    # Add new columns
    add_column :workout_exercises, :exercise_type, :string, default: 'strength', null: false
    add_column :workout_exercises, :sets, :integer, default: 3, null: false
    add_column :workout_exercises, :weight_lbs, :decimal, precision: 5, scale: 1
    add_column :workout_exercises, :notes, :text

    # Also add separate reps and duration_seconds columns
    add_column :workout_exercises, :reps, :integer
    add_column :workout_exercises, :duration_seconds, :integer

    # Backfill data from existing reps_or_duration
    WorkoutExercise.reset_column_information
    WorkoutExercise.find_each do |exercise|
      reps_or_duration = exercise.read_attribute_before_type_cast(:reps_or_duration)
      next unless reps_or_duration.present?

      # Try to parse as reps (e.g., "12", "12 reps", "3x12")
      if reps_or_duration.match?(/^\d+\s*x?\s*\d+$|^\d+\s*reps?$/)
        # Extract just the number (last one if "3x12" format)
        numbers = reps_or_duration.scan(/\d+/)
        exercise.update_columns(reps: numbers.last.to_i, exercise_type: 'strength')
      elsif reps_or_duration.match?(/\d+\s*(sec|second|min|minute|hr|hour)/)
        # Parse as duration (e.g., "30 seconds", "2 minutes")
        exercise.update_columns(duration_seconds: parse_duration_to_seconds(reps_or_duration), exercise_type: 'cardio')
      else
        # Default to strength and try to extract number
        number = reps_or_duration.scan(/\d+/).first
        exercise.update_columns(reps: number.to_i, exercise_type: 'strength') if number.present?
      end
    end

    # Make step_order unique per workout_plan
    add_index :workout_exercises, [:workout_plan_id, :step_order], unique: true, name: 'index_workout_exercises_on_plan_and_step_order'
  end

  def down
    # Remove indices
    remove_index :workout_exercises, name: 'index_workout_exercises_on_plan_and_step_order'

    # Remove new columns
    remove_column :workout_exercises, :exercise_type
    remove_column :workout_exercises, :sets
    remove_column :workout_exercises, :weight_lbs
    remove_column :workout_exercises, :notes
    remove_column :workout_exercises, :reps
    remove_column :workout_exercises, :duration_seconds
  end

  private

  def parse_duration_to_seconds(duration_string)
    case duration_string.downcase
    when /(\d+)\s*sec/
      Regexp.last_match(1).to_i
    when /(\d+)\s*min/
      Regexp.last_match(1).to_i * 60
    when /(\d+)\s*hr/
      Regexp.last_match(1).to_i * 3600
    else
      nil
    end
  end
end
