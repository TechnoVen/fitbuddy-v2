require "test_helper"

class AIServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @plan = @user.workout_plans.create!(
      goal: "build_muscle",
      level: "intermediate",
      duration_minutes: 60,
      equipment: ["dumbbells", "barbell"]
    )
    @exercise = @plan.workout_exercises.create!(
      name: "Squats",
      step_order: 1,
      exercise_type: "strength",
      description: "Bodyweight squats",
      sets: 3,
      reps: 10
    )
    ENV['OPENAI_API_KEY'] = 'test-key-12345'
  end

  # Test initialization
  test "should initialize with API key from environment" do
    service = AIService.new
    assert_not_nil service
  end

  test "should raise error if API key is missing" do
    original_key = ENV['OPENAI_API_KEY']
    ENV['OPENAI_API_KEY'] = nil
    
    assert_raises(AIService::AIServiceError) do
      AIService.new
    end
    
    ENV['OPENAI_API_KEY'] = original_key
  end

  # Test response parsing
  test "should parse exercise enhancement response correctly" do
    service = AIService.new
    
    response = <<~RESPONSE
      SUGGESTION: Increase intensity with heavier weights
      FORM_TIPS: Keep core engaged throughout the movement
      RECOMMENDED_VALUES: { "sets": 5, "reps": 5, "weight_lbs": 225 }
    RESPONSE
    
    result = service.send(:parse_exercise_enhancement_response, response)
    
    assert_equal false, result[:error]
    assert_includes result[:suggestion], "Increase intensity"
    assert_includes result[:form_tips], "core engaged"
    assert_equal 5, result[:enhanced_fields]["sets"]
  end

  test "should parse plan generation response with multiple exercises" do
    service = AIService.new
    
    response = <<~RESPONSE
      [
        {"name": "Deadlifts", "exercise_type": "strength", "sets": 3, "reps": 5, "weight_lbs": 315},
        {"name": "Pull-ups", "exercise_type": "strength", "sets": 3, "reps": 8}
      ]
    RESPONSE
    
    result = service.send(:parse_plan_generation_response, response)
    
    assert_equal false, result[:error]
    assert_equal 2, result[:exercises].count
    assert_equal 315, result[:exercises][0]["weight_lbs"]
  end

  test "should parse plan revision response with suggestions and updates" do
    service = AIService.new
    
    response = <<~RESPONSE
      SUGGESTIONS: 
      - Reduce volume by 30%
      - Add recovery day
      - Focus on compound lifts
      UPDATES: [{"name": "Bench Press", "sets": 3, "reps": 5}]
    RESPONSE
    
    result = service.send(:parse_plan_revision_response, response)
    
    assert_equal false, result[:error]
    assert result[:revision_suggestions].count > 0
    assert_equal 1, result[:updated_exercises].count
  end

  # Test edge cases
  test "should handle malformed JSON gracefully" do
    service = AIService.new
    response = "RECOMMENDED_VALUES: { sets: 3, reps: 10 }" # Missing quotes
    
    result = service.send(:parse_exercise_enhancement_response, response)
    
    assert_equal false, result[:error]
    assert_equal({}, result[:enhanced_fields])
  end

  test "should handle missing sections gracefully" do
    service = AIService.new
    response = "No expected sections in this response"
    
    result = service.send(:parse_exercise_enhancement_response, response)
    
    assert_equal false, result[:error]
    assert_not_nil result[:suggestion]
    assert_equal({}, result[:enhanced_fields])
  end

  # Test prompt building
  test "should build exercise enhancement prompt with correct fields" do
    service = AIService.new
    prompt = service.send(:build_exercise_enhancement_prompt, @exercise, @plan)
    
    assert_includes prompt, @exercise.name
    assert_includes prompt, @exercise.exercise_type
    assert_includes prompt, @plan.goal
  end

  test "build_chat_messages includes configured system prompt" do
    service = AIService.new
    AIConfig.load_config # ensure config loaded
    messages = service.send(:build_chat_messages, "Hello")

    assert_equal "system", messages.first[:role]
    assert_equal AIConfig.system_prompt.strip, messages.first[:content].strip
    assert_equal "user", messages.last[:role]
  end

  test "calls client.with_instructions when available" do
    service = AIService.new

    # Build a fake client that responds to with_instructions and chat_completion
    fake_client = Object.new

    def fake_client.with_instructions(system_prompt)
      @with_instructions_called = true
      # yield a client-like object (self) that responds to chat_completion
      yield self
    end

    def fake_client.chat_completion(**kwargs)
      { "choices" => [{ "message" => { "content" => "FAKE_OK" } }] }
    end

    def fake_client.with_instructions_called?
      !!@with_instructions_called
    end

    service.instance_variable_set(:@client, fake_client)

    # call the private method to trigger the wrapper usage
    result = service.send(:call_ai, "test prompt")

    assert_equal "FAKE_OK", result
    assert_predicate fake_client, :with_instructions_called?
  end

  test "should build plan generation prompt with plan details" do
    service = AIService.new
    prompt = service.send(:build_plan_generation_prompt, @plan)
    
    assert_includes prompt, @plan.goal
    assert_includes prompt, @plan.duration_minutes.to_s
    assert_includes prompt, @plan.level.titleize
  end

  test "should build plan revision prompt with feedback" do
    service = AIService.new
    messages = [{ role: "user", content: "Too difficult" }]
    
    prompt = service.send(:build_plan_revision_prompt, @plan, messages)
    
    assert_includes prompt, "Too difficult"
    assert_includes prompt, @plan.goal
  end

  # Test section extraction
  test "should extract section from response text" do
    service = AIService.new
    text = "SUGGESTION: This is a great suggestion\nFORM_TIPS: Keep core tight"
    section = service.send(:extract_section, text, "SUGGESTION")
    
    assert_equal "This is a great suggestion", section
  end

  test "should extract JSON from section" do
    service = AIService.new
    text = 'RECOMMENDED_VALUES: { "sets": 4, "reps": 10 }'
    json = service.send(:extract_json_section, text, "RECOMMENDED_VALUES")
    
    assert_equal 4, json["sets"]
    assert_equal 10, json["reps"]
  end

  test "should extract JSON array from response" do
    service = AIService.new
    text = '[{"name": "Exercise 1"}, {"name": "Exercise 2"}]'
    array = service.send(:extract_json_array, text)
    
    assert_equal 2, array.count
    assert_equal "Exercise 1", array[0]["name"]
  end
end
