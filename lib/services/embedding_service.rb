# frozen_string_literal: true

require 'openai'

class EmbeddingService
  MODEL = 'text-embedding-3-small'
  DIMENSIONS = 1536

  def initialize(api_key: ENV['OPENAI_API_KEY'])
    @client = OpenAI::Client.new(access_token: api_key)
  end

  # Returns an array of floats (embedding) for the given text
  def embed(text)
    response = @client.embeddings(parameters: {
      model: MODEL,
      input: text
    })
    response.dig('data', 0, 'embedding')
  end

  # Given a user question, returns the top N most similar WebsiteChunks
  def self.find_similar_chunks(question, limit: 5)
    embedding = new.embed(question)
    chunks = WebsiteChunk.similar_to(embedding, limit: limit)
    if chunks.empty?
      nil
    else
      chunks
    end
  end
end 