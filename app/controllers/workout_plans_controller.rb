class WorkoutPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout_plan, only: %i[show edit update destroy]
  before_action :authorize_user!, only: %i[show edit update destroy]

  def index
    @workout_plans = current_user.workout_plans.order(updated_at: :desc)
  end

  def show
  end

  def new
    @workout_plan = WorkoutPlan.new
  end

  def create
    @workout_plan = WorkoutPlan.new(workout_plan_params)
    @workout_plan.user = current_user

    # Generate AI plan if requested (default: true)
    @workout_plan.ai_plan = generate_ai_plan(@workout_plan) if params[:generate_ai_plan] != "0"

    if @workout_plan.save
      redirect_to @workout_plan
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workout_plan.update(workout_plan_params)
      redirect_to @workout_plan
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_plan.destroy
    redirect_to workout_plans_path, notice: "Workout plan deleted successfully."
  end

  private

  def workout_plan_params
    params.require(:workout_plan).permit(:age, :height, :weight, :handicap, :level, :goal, :equipment, :duration_minutes)
  end

  def set_workout_plan
    @workout_plan = WorkoutPlan.find(params[:id])
  end

  def authorize_user!
    redirect_to workout_plans_path, alert: "Not authorized" unless @workout_plan.user == current_user
  end

  def generate_ai_plan(workout_plan)
    prompt = <<~PROMPT
      Create a concise workout plan overview based on these details:
      - Age: #{workout_plan.age.present? ? workout_plan.age : 'Not specified'}
      - Height: #{workout_plan.height.present? ? "#{workout_plan.height} cm" : 'Not specified'}
      - Weight: #{workout_plan.weight.present? ? "#{workout_plan.weight} kg" : 'Not specified'}
      - Handicap: #{workout_plan.handicap.present? ? workout_plan.handicap : 'None'}
      - Goal: #{workout_plan.goal}
      - Level: #{workout_plan.level}
      - Duration: #{workout_plan.duration_minutes} minutes
      - Equipment: #{workout_plan.equipment.present? ? workout_plan.equipment : 'None'}

      Provide a brief 2-3 sentence overview of how to structure this workout (warm-up, sets, rest periods, intensity).
      Keep it practical and actionable.
    PROMPT

    begin
      ai_service = AIService.new
      ai_text = ai_service.chat(prompt)
      ai_text.presence || "No AI plan generated."
    rescue AIService::AIServiceError, StandardError => e
      Rails.logger.error "AI generation failed: #{e.class} - #{e.message}"
      "AI plan generation unavailable at this time."
    end
  end
end
