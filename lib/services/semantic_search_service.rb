# frozen_string_literal: true

require 'openai'

class SemanticSearchService
  def initialize(api_key: ENV['OPENAI_API_KEY'])
    @client = OpenAI::Client.new(access_token: api_key)
    validate_api_key!
  end

  # Main method: takes a question and returns relevant chunks
  def search(question, limit: 5)
    validate_question!(question)
    
    # Find similar chunks using semantic search
    chunks = WebsiteChunk.similar_chunks(question, limit: limit)
    
    if chunks.empty?
      {
        success: false,
        message: "No relevant information found for your question.",
        chunks: []
      }
    else
      {
        success: true,
        message: "Found #{chunks.count} relevant pieces of information.",
        chunks: chunks
      }
    end
  rescue => e
    Rails.logger.error("Semantic search failed: #{e.message}")
    {
      success: false,
      message: "Search failed: #{e.message}",
      chunks: []
    }
  end

  # Get chunks with their content formatted for display
  def search_with_content(question, limit: 5)
    result = search(question, limit: limit)
    
    if result[:success]
      result[:chunks] = result[:chunks].map do |chunk|
        {
          id: chunk.id,
          content: chunk.content,
          section: chunk.section,
          website_url: chunk.website.url
        }
      end
    end
    
    result
  end

  # Test the semantic search service
  def self.test_search
    service = new
    
    test_questions = [
      "What types of products do you sell?",
      "Tell me about your services",
      "What is your company about?"
    ]
    
    results = []
    test_questions.each do |question|
      result = service.search(question, limit: 3)
      results << {
        question: question,
        success: result[:success],
        chunk_count: result[:chunks].count
      }
    end
    
    results
  end

  private

  def validate_api_key!
    unless ENV['OPENAI_API_KEY'].present?
      raise "OPENAI_API_KEY environment variable is not set"
    end
  end

  def validate_question!(question)
    unless question.is_a?(String) && question.strip.present?
      raise "Question must be a non-empty string"
    end
  end
end 