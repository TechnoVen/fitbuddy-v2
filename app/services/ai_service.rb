require 'ruby_llm'
require 'net/http'

class AIService
  MAX_RETRIES = 3
  RETRY_DELAYS = [2, 4, 8].freeze # Exponential backoff: 2s, 4s, 8s

  class AIServiceError < StandardError; end
  class RateLimitError < AIServiceError; end
  class TimeoutError < AIServiceError; end
  class APIError < AIServiceError; end

  # Initialize AI service with API key from environment
  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @logger = Rails.logger
    
    raise AIServiceError, "OpenAI API key is not configured" if @api_key.blank?

    begin
      @client = RubyLLM::Client.new(api_key: @api_key)
    rescue NameError, LoadError => e
      # ruby_llm gem isn't available in the current environment (e.g., test runner).
      # Fall back to a nil client and allow methods that don't call the API to run.
      @logger.warn("AIService: ruby_llm not available, API calls will be disabled (#{e.class})")
      @client = nil
    end
  end

  # Enhance an exercise with AI suggestions
  # @param exercise [WorkoutExercise] The exercise to enhance
  # @param plan [WorkoutPlan] The workout plan context
  # @return [Hash] Contains 'suggestion' and 'enhanced_fields' keys
  def enhance_exercise(exercise, plan)
    @logger.info("AIService#enhance_exercise - Exercise: #{exercise.id}, Plan: #{plan.id}")

    prompt = build_exercise_enhancement_prompt(exercise, plan)
    response = call_ai_with_retry(prompt, "enhance_exercise")

    parse_exercise_enhancement_response(response)
  rescue AIServiceError => e
    @logger.error("AIService#enhance_exercise failed after retries: #{e.message}")
    {
      suggestion: "Could not generate suggestions at this time. Please try again later.",
      enhanced_fields: {},
      error: true
    }
  end

  # Generate a complete workout plan with AI
  # @param plan [WorkoutPlan] The workout plan to generate exercises for
  # @return [Hash] Contains 'exercises' array with suggested exercises
  def generate_plan(plan)
    @logger.info("AIService#generate_plan - Plan: #{plan.id}")

    prompt = build_plan_generation_prompt(plan)
    response = call_ai_with_retry(prompt, "generate_plan")

    parse_plan_generation_response(response)
  rescue AIServiceError => e
    @logger.error("AIService#generate_plan failed after retries: #{e.message}")
    {
      exercises: [],
      error: true,
      error_message: "Could not generate plan at this time. Please try again later."
    }
  end

  # Revise a workout plan based on user feedback via chat
  # @param plan [WorkoutPlan] The workout plan to revise
  # @param messages [Array<Hash>] Chat messages with feedback
  # @return [Hash] Contains 'revision_suggestions' and 'updated_exercises' keys
  def revise_plan(plan, messages)
    @logger.info("AIService#revise_plan - Plan: #{plan.id}, Messages: #{messages.count}")

    prompt = build_plan_revision_prompt(plan, messages)
    response = call_ai_with_retry(prompt, "revise_plan")

    parse_plan_revision_response(response)
  rescue AIServiceError => e
    @logger.error("AIService#revise_plan failed after retries: #{e.message}")
    {
      revision_suggestions: [],
      updated_exercises: [],
      error: true,
      error_message: "Could not revise plan at this time. Please try again later."
    }
  end

  private

  # Call AI API with exponential backoff retry logic
  # @param prompt [String] The prompt to send to the AI
  # @param action [String] The action name for logging
  # @return [String] The AI response text
  def call_ai_with_retry(prompt, action)
    attempt = 0

    loop do
      attempt += 1
      @logger.debug("AIService#call_ai_with_retry - Attempt #{attempt}/#{MAX_RETRIES}, Action: #{action}")

      begin
        response = call_ai(prompt)
        @logger.info("AIService#call_ai_with_retry - Success on attempt #{attempt}, Action: #{action}")
        return response
      rescue RateLimitError, TimeoutError => e
        if attempt < MAX_RETRIES
          delay = RETRY_DELAYS[attempt - 1]
          @logger.warn("AIService#call_ai_with_retry - #{e.class.name} on attempt #{attempt}, retrying in #{delay}s")
          sleep(delay)
        else
          @logger.error("AIService#call_ai_with_retry - Max retries exceeded after #{MAX_RETRIES} attempts")
          raise AIServiceError, "Failed to connect to AI service after #{MAX_RETRIES} retries: #{e.message}"
        end
      rescue APIError => e
        @logger.error("AIService#call_ai_with_retry - Non-recoverable APIError: #{e.message}")
        raise
      end
    end
  end

  # Make actual API call to OpenAI
  # @param prompt [String] The prompt to send
  # @return [String] The response text
  def call_ai(prompt)
    begin
      timeout_seconds = 30
      response = @client.chat_completion(
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are a professional fitness coach and workout planner." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1000,
        timeout: timeout_seconds
      )

      extract_response_text(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise TimeoutError, "API request timed out: #{e.message}"
    rescue RubyLLM::RateLimitError => e
      raise RateLimitError, "API rate limit exceeded: #{e.message}"
    rescue => e
      raise APIError, "Unexpected API error: #{e.class.name} - #{e.message}"
    end
  end

  # Extract text from API response
  # @param response [Hash] The API response object
  # @return [String] Extracted text
  def extract_response_text(response)
    if response.is_a?(Hash)
      response.dig("choices", 0, "message", "content") ||
      response.dig(:choices, 0, :message, :content) ||
      raise(APIError, "Invalid response structure from API")
    else
      response.to_s
    end
  end

  # Build prompt for exercise enhancement
  # @param exercise [WorkoutExercise] The exercise to enhance
  # @param plan [WorkoutPlan] The workout plan context
  # @return [String] The formatted prompt
  def build_exercise_enhancement_prompt(exercise, plan)
    <<~PROMPT
      You are a fitness coach. Analyze this exercise and provide enhancement suggestions.

      Exercise Details:
      - Name: #{exercise.name}
      - Type: #{exercise.exercise_type}
      - Description: #{exercise.description}
      - Sets: #{exercise.sets || "Not specified"}
      - Reps: #{exercise.reps || "Not specified"}
      - Duration: #{exercise.duration_seconds&.then { |d| "#{d} seconds" } || "Not specified"}
      - Weight: #{exercise.weight_lbs&.then { |w| "#{w} lbs" } || "Not specified"}
      - Rest: #{exercise.rest_seconds&.then { |r| "#{r} seconds" } || "Not specified"}

      Workout Plan Context:
      - Goal: #{plan.goal}
      - Duration: #{plan.duration_minutes} minutes
      - Level: #{plan.level}

      Provide:
      1. A brief suggestion to improve this exercise (1-2 sentences)
      2. Recommended values in JSON format: { "sets": number, "reps": number, "weight_lbs": number, "duration_seconds": number }
      3. Form tips or modifications

      Format your response as:
      SUGGESTION: [your suggestion]
      FORM_TIPS: [tips]
      RECOMMENDED_VALUES: [json object]
    PROMPT
  end

  # Build prompt for plan generation
  # @param plan [WorkoutPlan] The workout plan
  # @return [String] The formatted prompt
  def build_plan_generation_prompt(plan)
    <<~PROMPT
      You are a professional fitness coach. Generate a complete workout plan.

      Plan Requirements:
      - Goal: #{plan.goal}
      - Duration: #{plan.duration_minutes} minutes per session
      - Level: #{plan.level}
      - User Level: #{plan.level.titleize}
      - Equipment Available: #{
        if plan.respond_to?(:equipment) && plan.equipment.present?
          plan.equipment.is_a?(Array) ? plan.equipment.join(", ") : plan.equipment.to_s
        else
          "None specified"
        end
      }

      Create a realistic, structured workout plan with 4-8 exercises that:
      1. Progresses logically
      2. Matches the duration (#{plan.duration_minutes} minutes)
      3. Is appropriate for #{plan.level.titleize} users
      4. Achieves the stated goal

      For each exercise, provide:
      - Name (descriptive)
      - Type (strength/cardio/flexibility)
      - Sets (for strength)
      - Reps (for strength)
      - Duration in seconds (for cardio/flexibility)
      - Weight in lbs (if applicable)
      - Rest between sets in seconds
      - Brief description with form tips

      Format as a JSON array:
      [
        {
          "name": "Exercise Name",
          "exercise_type": "strength|cardio|flexibility",
          "sets": number,
          "reps": number,
          "duration_seconds": number,
          "weight_lbs": number,
          "rest_seconds": number,
          "description": "Description with form tips"
        }
      ]
    PROMPT
  end

  # Build prompt for plan revision
  # @param plan [WorkoutPlan] The workout plan to revise
  # @param messages [Array<Hash>] Chat messages with feedback
  # @return [String] The formatted prompt
  def build_plan_revision_prompt(plan, messages)
    feedback_text = messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")

    <<~PROMPT
      You are a fitness coach. A user has provided feedback on their workout plan.

      Current Plan:
      - Goal: #{plan.goal}
      - Duration: #{plan.duration_minutes} minutes
      - Level: #{plan.level}

      Current Exercises: (#{plan.workout_exercises.count} total)
      #{format_current_exercises(plan)}

      User Feedback:
      #{feedback_text}

      Based on the feedback, provide:
      1. Specific revision suggestions (2-3 bullet points)
      2. Recommendations for which exercises to modify or replace
      3. Updated exercise details in JSON format

      Format as:
      SUGGESTIONS: [bullet points]
      UPDATES: [json array of updated exercises]
    PROMPT
  end

  # Format current exercises for the prompt
  # @param plan [WorkoutPlan] The workout plan
  # @return [String] Formatted exercises
  def format_current_exercises(plan)
    plan.workout_exercises.order(:step_order).map do |ex|
      "#{ex.step_order}. #{ex.name} (#{ex.exercise_type})"
    end.join("\n")
  end

  # Parse AI response for exercise enhancement
  # @param response [String] The AI response
  # @return [Hash] Parsed enhancement data
  def parse_exercise_enhancement_response(response)
    @logger.debug("Parsing exercise enhancement response")

    suggestion = extract_section(response, "SUGGESTION")
    form_tips = extract_section(response, "FORM_TIPS")
    recommended_values = extract_json_section(response, "RECOMMENDED_VALUES")

    {
      suggestion: suggestion || "Enhancement suggestion generated",
      form_tips: form_tips || "Follow proper form techniques",
      enhanced_fields: recommended_values || {},
      error: false
    }
  rescue => e
    @logger.warn("Failed to parse exercise enhancement response: #{e.message}")
    {
      suggestion: "Enhancement suggestion generated",
      enhanced_fields: {},
      error: false
    }
  end

  # Parse AI response for plan generation
  # @param response [String] The AI response
  # @return [Hash] Parsed plan data
  def parse_plan_generation_response(response)
    @logger.debug("Parsing plan generation response")

    exercises = extract_json_array(response)

    {
      exercises: exercises || [],
      error: false
    }
  rescue => e
    @logger.warn("Failed to parse plan generation response: #{e.message}")
    {
      exercises: [],
      error: false
    }
  end

  # Parse AI response for plan revision
  # @param response [String] The AI response
  # @return [Hash] Parsed revision data
  def parse_plan_revision_response(response)
    @logger.debug("Parsing plan revision response")

    suggestions = extract_section(response, "SUGGESTIONS")
    updates = extract_json_section(response, "UPDATES") || []

    {
      revision_suggestions: suggestions&.split("\n") || [],
      updated_exercises: updates.is_a?(Array) ? updates : [],
      error: false
    }
  rescue => e
    @logger.warn("Failed to parse plan revision response: #{e.message}")
    {
      revision_suggestions: [],
      updated_exercises: [],
      error: false
    }
  end

  # Extract a section from the response text
  # @param text [String] The response text
  # @param section_name [String] The section name to extract
  # @return [String] The section content
  def extract_section(text, section_name)
    regex = /#{section_name}:\s*(.+?)(?=\n[A-Z_]+:|$)/m
    match = text.match(regex)
    match&.captures&.first&.strip
  end

  # Extract JSON from a section
  # @param text [String] The response text
  # @param section_name [String] The section name
  # @return [Object] Parsed JSON object
  def extract_json_section(text, section_name)
    content = extract_section(text, section_name)
    return nil unless content

    # Try to find JSON in the content
    json_match = content.match(/\{[\s\S]*\}|\[[\s\S]*\]/)
    return nil unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    @logger.debug("Failed to parse JSON from section #{section_name}: #{e.message}")
    nil
  end

  # Extract JSON array from response
  # @param text [String] The response text
  # @return [Array] Parsed JSON array
  def extract_json_array(text)
    json_match = text.match(/\[\s*\{[\s\S]*?\}\s*\]/m)
    return nil unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    @logger.debug("Failed to parse JSON array: #{e.message}")
    nil
  end
end
