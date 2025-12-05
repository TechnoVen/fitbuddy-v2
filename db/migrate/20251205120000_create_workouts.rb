class CreateWorkouts < ActiveRecord::Migration[7.1]
  def change
    create_table :workouts do |t|
      t.references :workout_plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes
      t.integer :completion_percentage, null: false, default: 0

      t.timestamps
    end

    add_index :workouts, [:user_id, :workout_plan_id]
  end
end
