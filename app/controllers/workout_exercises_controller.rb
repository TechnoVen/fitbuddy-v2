class WorkoutExercisesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout_plan
  before_action :set_workout_exercise, only: %i[edit update destroy]

  def new
    @workout_exercise = @workout_plan.workout_exercises.new
  end

  def create
    @workout_exercise = @workout_plan.workout_exercises.new(workout_exercise_params)
    if @workout_exercise.save
      redirect_to workout_plan_path(@workout_plan), notice: "Exercise added."
    else
      flash.now[:alert] = "Could not add exercise."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # If the user requests AI assistance (preview), call the AI service and show suggestions
    if params[:ai_assist] == "1" && params[:ai_accept] != "1"
      # Assign submitted values locally so AI has current context (do not save yet)
      @workout_exercise.assign_attributes(workout_exercise_params)

      begin
        ai_service = AIService.new
        ai_result = ai_service.enhance_exercise(@workout_exercise, @workout_plan)
      rescue StandardError => e
        Rails.logger.error("AIService initialize/call failed: #{e.class} - #{e.message}")
        ai_result = { suggestion: "AI is unavailable right now.", enhanced_fields: {}, error: true }
      end

      # Persist suggestion in session temporarily keyed by exercise id
      session[:ai_suggestions] ||= {}
      session[:ai_suggestions][@workout_exercise.id.to_s] = ai_result

      @ai_result = ai_result
      flash.now[:notice] = "AI suggestions generated — review below and apply if you like."
      render :edit and return
    end

    # If the user accepted AI suggestion, merge suggested fields from session into params
    if params[:ai_accept] == "1"
      suggestion = session.dig(:ai_suggestions, @workout_exercise.id.to_s) || {}
      enhanced = suggestion['enhanced_fields'] || suggestion[:enhanced_fields] || {}

      # Merge enhanced fields into the permitted params (string keys handled)
      merged = workout_exercise_params.to_h.merge(enhanced.transform_keys(&:to_s))

      # Clear stored suggestion after applying
      session[:ai_suggestions]&.delete(@workout_exercise.id.to_s)

      if @workout_exercise.update(merged)
        redirect_to workout_plan_path(@workout_plan), notice: "Exercise updated with AI suggestions."
      else
        flash.now[:alert] = "Could not update exercise."
        render :edit, status: :unprocessable_entity
      end
      return
    end

    if @workout_exercise.update(workout_exercise_params)
      redirect_to workout_plan_path(@workout_plan), notice: "Exercise updated."
    else
      flash.now[:alert] = "Could not update exercise."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_exercise.destroy
    redirect_to workout_plan_path(@workout_plan), notice: "Exercise deleted."
  end

  private

  def set_workout_plan
    @workout_plan = WorkoutPlan.find(params[:workout_plan_id])
  end

  def set_workout_exercise
    @workout_exercise = @workout_plan.workout_exercises.find(params[:id])
  end

  def workout_exercise_params
    params.require(:workout_exercise).permit(
      :step_order,
      :name,
      :description,
      :exercise_type,
      :sets,
      :reps,
      :duration_seconds,
      :weight_lbs,
      :rest_seconds,
      :notes
    )
  end
end
