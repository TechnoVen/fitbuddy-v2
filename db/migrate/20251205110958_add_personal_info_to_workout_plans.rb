class AddPersonalInfoToWorkoutPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_plans, :age, :integer
    add_column :workout_plans, :height, :integer
    add_column :workout_plans, :weight, :integer
    add_column :workout_plans, :handicap, :string
  end
end
