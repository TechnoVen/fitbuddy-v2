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
      chat_llm = RubyLLM.chat
      ai_response = chat_llm.ask(prompt)
      new_plan = ai_response.respond_to?(:content) ? ai_response.content.to_s : ai_response.to_s

      # Update the workout plan
      @workout_plan.update!(ai_plan: new_plan)

      # Save AI message to chat history
      @chat.ai_messages.create!(
        user: current_user,
        workout_plan: @workout_plan,
        role: "assistant",
        content: "✅ I've revised your workout plan based on our conversation:\n\n#{new_plan}"
      )

      redirect_to workout_plan_chat_path(@workout_plan, @chat),
                  notice: "Workout plan successfully updated!"
    rescue StandardError => e
      Rails.logger.error "Plan revision failed: #{e.message}"
      redirect_to workout_plan_chat_path(@workout_plan, @chat),
                  alert: "Sorry, I couldn't revise the plan right now. Please try again."
    end
  end

  private

  def set_workout_plan
    @workout_plan = current_user.workout_plans.find(params[:workout_plan_id])
  end
end
