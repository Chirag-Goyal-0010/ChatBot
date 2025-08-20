class WebsiteChunk < ApplicationRecord
  belongs_to :website
  
  validates :content, presence: true
  validates :embedding, presence: true, on: :update
  
  # Check if vector search is available
  def self.vector_search_available?
    return @vector_search_available if defined?(@vector_search_available)
    
    @vector_search_available = begin
      connection.column_exists?(:website_chunks, :embedding) &&
      connection.columns(:website_chunks).find { |c| c.name == 'embedding' }&.sql_type&.include?('vector')
    rescue => e
      Rails.logger.warn "Could not check vector availability: #{e.message}"
      false
    end
  end

  # Semantic search method using pgvector cosine distance
  def self.similar_chunks(question, limit: 5)
    return none unless question.present?
    
    unless vector_search_available?
      Rails.logger.warn "Vector search not available - falling back to text search"
      return text_search_fallback(question, limit)
    end
    
    begin
      # Generate embedding for the question
      service = EmbeddingService.new
      question_embedding = service.embed(question)
      
      # Use pgvector cosine distance operator
      where.not(embedding: nil)
        .order(Arel.sql("embedding <=> #{ActiveRecord::Base.connection.quote(question_embedding)} ASC"))
        .limit(limit)
    rescue => e
      Rails.logger.error("Semantic search failed: #{e.message}")
      text_search_fallback(question, limit)
    end
  end
  
  # Fallback text search when vector search is unavailable
  def self.text_search_fallback(question, limit: 5)
    keywords = question.downcase.split(/\W+/).reject(&:blank?)
    return none if keywords.empty?
    
    query = keywords.map { |keyword| "content ILIKE ?" }.join(" OR ")
    params = keywords.map { |keyword| "%#{keyword}%" }
    
    where(query, *params)
      .order(created_at: :desc)
      .limit(limit)
  end



  # Returns the top N most similar chunks to the given embedding
  def self.similar_to(embedding, limit: 5)
    return none unless embedding.is_a?(Array) && embedding.length == 1536
    
    unless vector_search_available?
      Rails.logger.warn "Vector search not available for similarity search"
      return limit(limit)
    end
    
    where.not(embedding: nil)
      .order(Arel.sql("embedding <=> #{ActiveRecord::Base.connection.quote(embedding)} ASC"))
      .limit(limit)
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
