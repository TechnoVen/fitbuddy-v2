class WorkoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout_plan
  before_action :set_workout, only: [:show]
  before_action :authorize_user!

  def new
    @workout = @workout_plan.workouts.new
  end

  def create
    @workout = @workout_plan.workouts.new(workout_params)
    @workout.user = current_user
    @workout.started_at ||= Time.current

    if @workout.save
      redirect_to workout_plan_workout_path(@workout_plan, @workout), notice: "Workout started."
    else
      flash.now[:alert] = "Could not start workout."
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @workout_logs = @workout.workout_logs.order(created_at: :asc)
  end

  private

  def set_workout_plan
    @workout_plan = WorkoutPlan.find(params[:workout_plan_id])
  end

  def set_workout
    @workout = @workout_plan.workouts.find(params[:id])
  end

  def authorize_user!
    return if @workout_plan.user == current_user

    redirect_to root_path, alert: "Not authorized"
  end

  def workout_params
    params.require(:workout).permit(:started_at, :notes)
  end
end
