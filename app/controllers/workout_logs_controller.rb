class WorkoutLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout
  before_action :set_workout_exercise, only: [:new]

  def index
    @workout_logs = @workout.workout_logs.order(created_at: :desc)
  end

  def new
    @workout_log = @workout.workout_logs.new
  end

  def create
    @workout_log = @workout.workout_logs.new(workout_log_params)
    if @workout_log.save
      redirect_to workout_workout_logs_path(@workout), notice: "Log recorded."
    else
      flash.now[:alert] = "Could not save log."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_workout
    @workout = Workout.find(params[:workout_id])
  end

  def set_workout_exercise
    @workout_exercise = WorkoutExercise.find_by(id: params[:workout_exercise_id]) if params[:workout_exercise_id].present?
  end

  def workout_log_params
    params.require(:workout_log).permit(:workout_exercise_id, :completed, :reps, :duration_seconds, :weight_lbs, :notes)
  end
end
