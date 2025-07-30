require Rails.root.join('lib', 'services', 'embedding_service')

class WebsiteChunk < ApplicationRecord
  belongs_to :website
  before_save :generate_embedding, if: -> { content_changed? }
  
  validates :content, presence: true
  validates :embedding, presence: true, on: :update

  # Semantic search method using pgvector cosine distance
  def self.similar_chunks(question, limit: 5)
    return none unless question.present?
    
    begin
      # Generate embedding for the question
      service = EmbeddingService.new
      question_embedding = service.embed(question)
      
      # Use pgvector cosine distance operator
      order(Arel.sql("embedding <=> '[#{question_embedding.join(',')}]' ASC"))
        .limit(limit)
    rescue => e
      Rails.logger.error("Semantic search failed: #{e.message}")
      none
    end
  end

  private

  def generate_embedding
    begin
      service = EmbeddingService.new
      embedding_array = service.embed(content)
      
      if embedding_array && embedding_array.is_a?(Array) && embedding_array.length == 1536
        # Convert array to pgvector format
        self.embedding = "[#{embedding_array.join(',')}]"
      else
        errors.add(:embedding, "Failed to generate valid embedding")
        throw(:abort)
      end
    rescue => e
      errors.add(:embedding, "Error generating embedding: #{e.message}")
      throw(:abort)
    end
  end

  # Returns the top N most similar chunks to the given embedding
  def self.similar_to(embedding, limit: 5)
    return none unless embedding.is_a?(Array) && embedding.length == 1536
    
    order(Arel.sql("embedding <-> '[#{embedding.join(',')}]' ASC")).limit(limit)
  end
  
  # Test method to verify vector storage
  def self.test_vector_storage
    website = Website.first || Website.create!(url: "https://test.com", status: "active")
    chunk = create!(
      website: website,
      content: "This is a test chunk for vector storage verification.",
      section: "test"
    )
    chunk.reload
    {
      id: chunk.id,
      has_embedding: chunk.embedding.present?,
      embedding_length: chunk.embedding&.length,
      content: chunk.content
    }
  end
end
