# frozen_string_literal: true

require 'openai'

class EmbeddingService
  MODEL = 'text-embedding-3-small'
  DIMENSIONS = 1536

  def initialize(api_key: ENV['OPENAI_API_KEY'])
    @client = OpenAI::Client.new(access_token: api_key)
    validate_api_key!
  end

  # Returns an array of floats (embedding) for the given text
  def embed(text)
    validate_input!(text)
    
    response = @client.embeddings(parameters: {
      model: MODEL,
      input: text
    })
    
    embedding = response.dig('data', 0, 'embedding')
    validate_embedding!(embedding)
    embedding
  rescue => e
    Rails.logger.error("Embedding generation failed: #{e.message}")
    raise "Failed to generate embedding: #{e.message}"
  end

  # Insert embedding directly into WebsiteChunk
  def insert_embedding_for_chunk(chunk)
    return false unless chunk.is_a?(WebsiteChunk)
    
    begin
      embedding_array = embed(chunk.content)
      chunk.update!(embedding: "[#{embedding_array.join(',')}]")
      true
    rescue => e
      Rails.logger.error("Failed to insert embedding for chunk #{chunk.id}: #{e.message}")
      false
    end
  end

  # Batch process multiple chunks
  def self.batch_embed_chunks(chunks)
    service = new
    results = { success: 0, failed: 0, errors: [] }
    
    chunks.find_each do |chunk|
      if service.insert_embedding_for_chunk(chunk)
        results[:success] += 1
      else
        results[:failed] += 1
        results[:errors] << "Chunk #{chunk.id}: #{chunk.content[0..50]}..."
      end
    end
    
    results
  end

  # Given a user question, returns the top N most similar WebsiteChunks
  def self.find_similar_chunks(question, limit: 5)
    validate_question!(question)
    
    embedding = new.embed(question)
    chunks = WebsiteChunk.similar_to(embedding, limit: limit)
    
    if chunks.empty?
      nil
    else
      chunks
    end
  rescue => e
    Rails.logger.error("Similarity search failed: #{e.message}")
    nil
  end
  
  # Batch process multiple texts
  def self.batch_embed(texts)
    return [] if texts.empty?
    
    service = new
    texts.map { |text| service.embed(text) }
  rescue => e
    Rails.logger.error("Batch embedding failed: #{e.message}")
    []
  end
  
  # Test the embedding service
  def self.test_service
    begin
      service = new
      test_text = "This is a test for the embedding service."
      embedding = service.embed(test_text)
      
      {
        success: true,
        embedding_length: embedding.length,
        dimensions_match: embedding.length == DIMENSIONS,
        test_text: test_text
      }
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def validate_api_key!
    unless ENV['OPENAI_API_KEY'].present?
      raise "OPENAI_API_KEY environment variable is not set"
    end
  end

  def validate_input!(text)
    unless text.is_a?(String) && text.strip.present?
      raise "Input must be a non-empty string"
    end
  end

  def validate_embedding!(embedding)
    unless embedding.is_a?(Array) && embedding.length == DIMENSIONS
      raise "Invalid embedding format or dimensions"
    end
  end

  def self.validate_question!(question)
    unless question.is_a?(String) && question.strip.present?
      raise "Question must be a non-empty string"
    end
  end
end 