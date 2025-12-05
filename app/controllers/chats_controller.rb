class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout_plan

  def show
    @chat = @workout_plan.chats.find(params[:id])
    @ai_messages = @chat.ai_messages.order(created_at: :asc)
    @ai_message = AiMessage.new
  end

  def create
    @chat = @workout_plan.chats.create!(
      user: current_user,
      title: params[:title].presence || "Chat for #{@workout_plan.goal}"
    )
    redirect_to workout_plan_chat_path(@workout_plan, @chat)
  end

  def revise_plan
    @chat = @workout_plan.chats.find(params[:id])

    # Get recent conversation context
    recent_messages = @chat.ai_messages.order(:created_at).last(5).map do |msg|
      "#{msg.role.capitalize}: #{msg.content}"
    end.join("\n\n")

    # Generate revised plan based on conversation
    prompt = <<~TEXT
    You are a workout planning assistant. Review this conversation and create an improved workout plan.

    Original Plan:
    #{@workout_plan.ai_plan || "No plan yet"}

    Personal Information:
    - Age: #{@workout_plan.age.present? ? @workout_plan.age : 'Not specified'}
    - Height: #{@workout_plan.height.present? ? "#{@workout_plan.height} cm" : 'Not specified'}
    - Weight: #{@workout_plan.weight.present? ? "#{@workout_plan.weight} kg" : 'Not specified'}
    - Handicap: #{@workout_plan.handicap.present? ? @workout_plan.handicap : 'None'}

      Level: #{@workout_plan.level}
      Duration: #{@workout_plan.duration_minutes} minutes
      Equipment: #{@workout_plan.equipment || 'None'}

      Recent Conversation:
      #{recent_messages}

      Based on the user's feedback and requests in this conversation, create a revised 2-3 sentence#{' '}
      workout plan overview. Focus on incorporating their specific needs and preferences mentioned in the chat.
      Keep it practical and actionable.
    TEXT

    begin
      ai_service = AIService.new

      # Use the AIService.revise_plan which returns structured revision suggestions
      result = ai_service.revise_plan(@workout_plan, @chat.ai_messages.order(:created_at).last(10).map { |m| { role: m.role, content: m.content } })

      if result[:error]
        raise AIService::AIServiceError, (result[:error_message] || "AI revision failed")
      end

      # Build a human-readable proposed plan overview from suggestions if present
      proposed_overview = if result[:revision_suggestions].present?
                            result[:revision_suggestions].join("\n")
                          elsif result[:updated_exercises].present?
                            "AI suggests updates to exercises"
                          else
                            "AI produced a revision"
                          end

      # Render a preview showing structured diffs and allow inline apply via Turbo Streams
      @preview = {
        original_overview: @workout_plan.ai_plan || "(no existing AI overview)",
        proposed_overview: proposed_overview,
        revision_suggestions: result[:revision_suggestions] || [],
        updated_exercises: result[:updated_exercises] || []
      }

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("plan_revision_preview", partial: "chats/revise_plan_preview", locals: { preview: @preview, chat: @chat, workout_plan: @workout_plan })
        end
        format.html { render :revise_plan_preview }
      end
    rescue AIService::AIServiceError, StandardError => e
      Rails.logger.error "Plan revision failed: #{e.class} - #{e.message}"
      redirect_to workout_plan_chat_path(@workout_plan, @chat), alert: "Sorry, I couldn't revise the plan right now. Please try again."
    end
  end

  # Apply the AI-proposed revision after user preview/confirmation
  def apply_revision
    @chat = @workout_plan.chats.find(params[:id])

    proposed_overview = params[:proposed_overview]
    proposed_exercises_json = params[:proposed_exercises_json]
    apply_overview = params[:apply_overview].present? || params[:apply_overview] == '1'
    apply_exercise_indexes = Array(params[:apply_exercises]).map(&:to_i)

    begin
      ActiveRecord::Base.transaction do
        # Apply overview text if provided
        if proposed_overview.present?
          @workout_plan.update!(ai_plan: proposed_overview)
        end

        # Apply updated exercises if provided (JSON array)
        if proposed_exercises_json.present?
          parsed = JSON.parse(proposed_exercises_json) rescue []

          parsed.each do |ex_hash|
            # Try to find by name (case-insensitive) or step_order if provided
            ex = if ex_hash['step_order']
                   @workout_plan.workout_exercises.find_by(step_order: ex_hash['step_order'])
                 else
                   @workout_plan.workout_exercises.find_by('lower(name) = ?', ex_hash['name'].to_s.downcase)
                 end

            attrs = ex_hash.slice('name', 'exercise_type', 'sets', 'reps', 'duration_seconds', 'weight_lbs', 'rest_seconds', 'description')

            if ex
              ex.update!(attrs.compact)
            else
              # create new exercise appended to the end
              max_step = @workout_plan.workout_exercises.maximum(:step_order) || 0
              attrs['step_order'] ||= max_step + 1
              @workout_plan.workout_exercises.create!(attrs.merge(user_id: @workout_plan.user_id))
            end
          end
        end
      end

      # Save an assistant message summarizing the applied changes
      summary = "Applied AI revision"
      summary += ": overview updated" if proposed_overview.present?
      summary += ", exercises updated" if proposed_exercises_json.present?

      @chat.ai_messages.create!(
        user: current_user,
        workout_plan: @workout_plan,
        role: "assistant",
        content: "✅ #{summary}."
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("plan_revision_preview", partial: "chats/revision_applied", locals: { workout_plan: @workout_plan, chat: @chat })
        end
        format.html { redirect_to workout_plan_chat_path(@workout_plan, @chat), notice: "AI revision applied." }
      end
    rescue StandardError => e
      Rails.logger.error "Failed to apply AI revision: #{e.class} - #{e.message}"
      redirect_to workout_plan_chat_path(@workout_plan, @chat), alert: "Failed to apply AI revision."
    end
  end

  private

  def set_workout_plan
    @workout_plan = current_user.workout_plans.find(params[:workout_plan_id])
  end
end
