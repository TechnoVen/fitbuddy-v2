class AiMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout_plan
  before_action :set_chat

  def create
    # 1) Save user message
    user_message = @chat.ai_messages.create!(
      user: current_user,
      workout_plan: @workout_plan,
      role: "user",
      content: params.require(:ai_message).fetch(:content)
    )

    # 2) Build chat history as plain text
    history_text = @chat.ai_messages.order(:created_at).map do |msg|
      speaker = msg.role == "user" ? "User" : "AI"
      "#{speaker}: #{msg.content}"
    end.join("\n")

    # 3) Build prompt
    prompt = <<~TEXT
      You are a workout assistant. Answer concisely.

      Conversation so far:
      #{history_text}

      User: #{user_message.content}
    TEXT

    # 4) Get AI response with error handling
    begin
      chat_llm    = RubyLLM.chat
      ai_response = chat_llm.ask(prompt)

      ai_text =
        if ai_response.respond_to?(:content)
          ai_response.content.to_s        # Extract response text from RubyLLM
        else
          ai_response.to_s                # Fallback if API object changes
        end

      # 5) Save AI message
      @chat.ai_messages.create!(
        user: current_user,
        workout_plan: @workout_plan,
        role: "assistant",
        content: ai_text
      )

      # 6) Redirect back to chat
      redirect_to workout_plan_chat_path(@workout_plan, @chat), notice: "AI response received."
    rescue StandardError => e
      Rails.logger.error "AI API Error: #{e.message}"
      redirect_to workout_plan_chat_path(@workout_plan, @chat),
                  alert: "Sorry, the AI service is temporarily unavailable. Please try again later."
    end
  end

  private

  def set_workout_plan
    @workout_plan = current_user.workout_plans.find(params[:workout_plan_id])
  end

  def set_chat
    @chat = @workout_plan.chats.find(params[:chat_id])
  end
end
