class CreateWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_logs do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :workout_exercise, foreign_key: true
      t.boolean :completed, null: false, default: false
      t.integer :reps
      t.integer :duration_seconds
      t.decimal :weight_lbs, precision: 6, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :workout_logs, :workout_id, if_not_exists: true
  end
end
