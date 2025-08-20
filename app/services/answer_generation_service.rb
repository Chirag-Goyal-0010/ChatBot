require 'openai'
require 'timeout'

class AnswerGenerationService
  def initialize(question, user_id = nil)
    @question = question
    @user_id = user_id
    @search_service = SemanticSearchService.new
  end

  def generate_answer
    validate_question
    
    # Check cache first for repeated questions
    cached_answer = CachingService.get_cached_ai_answer(@question)
    return cached_answer if cached_answer
    
    # Check if we have any chunks in the database
    chunk_count = WebsiteChunk.count
    if chunk_count == 0
      return build_error_response("No content has been scraped yet. Please submit a website URL first to scrape content before asking questions.")
    end
    
    # Find relevant chunks using semantic search
    search_result = perform_semantic_search
    
    if search_result[:success] && search_result[:chunks].any?
      ai_answer = generate_ai_response(search_result[:chunks])
      response = build_success_response(ai_answer, search_result[:chunks])
      
      # Cache successful responses
      CachingService.cache_ai_answer(@question, response)
      response
    else
      build_fallback_response
    end
  rescue => e
    Rails.logger.error("Answer generation failed: #{e.message}")
    build_error_response("Sorry, I encountered an error while processing your question. Please try again in a moment.")
  end

  private

  def validate_question
    validation_result = QuestionValidator.validate(@question)
    unless validation_result[:valid]
      raise validation_result[:error]
    end
  end

  def perform_semantic_search
    Timeout::timeout(5) do
      @search_service.search(@question, limit: 5)
    end
  rescue Timeout::Error => e
    Rails.logger.error("Semantic search timed out: #{e.message}")
    { success: false, message: "Search timed out", chunks: [] }
  rescue => e
    Rails.logger.error("Semantic search failed: #{e.message}")
    { success: false, message: "Search failed", chunks: [] }
  end

  def generate_ai_response(chunks)
    chunks_text = format_chunks_for_prompt(chunks)
    
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    prompt = build_prompt(chunks_text)
    
    response = client.chat(parameters: {
      model: ENV.fetch('OPENAI_CHAT_MODEL', 'gpt-4o-mini'),
      messages: [
        { role: "system", content: "You are a helpful AI assistant that answers questions based on provided information." },
        { role: "user", content: prompt }
      ],
      max_tokens: 500,
      temperature: 0.7
    })

    response.dig("choices", 0, "message", "content") || "Sorry, I couldn't generate an answer."
  rescue => e
    Rails.logger.error("OpenAI completion failed: #{e.message}")
    "Sorry, I encountered an error while generating the answer."
  end

  def build_prompt(chunks_text)
    <<~PROMPT
      You are a helpful AI assistant. Based on the following information, please answer the user's question.

      Information:
      #{chunks_text}

      Question: #{@question}

      Please provide a clear, helpful answer based on the information above. If the information doesn't contain enough details to answer the question, say so.
    PROMPT
  end

  def format_chunks_for_prompt(chunks)
    chunks.map.with_index(1) do |chunk, index|
      "Source #{index}:\n#{chunk.content}\n"
    end.join("\n")
  end

  def build_success_response(answer, chunks)
    {
      question: @question,
      answer: answer,
      chunks: chunks,
      success: true,
      timestamp: Time.current.to_i
    }
  end

  def build_fallback_response
    {
      question: @question,
      answer: "I'm having trouble finding specific information for your question. Please try rephrasing your question or ask something else.",
      chunks: [],
      success: true,
      timestamp: Time.current.to_i
    }
  end

  def build_error_response(error_message)
    {
      question: @question,
      answer: error_message,
      chunks: [],
      success: false,
      timestamp: Time.current.to_i
    }
  end
end 