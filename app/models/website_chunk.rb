class WebsiteChunk < ApplicationRecord
  belongs_to :website
  before_save :generate_embedding, if: -> { content_changed? }

  private

  def generate_embedding
    service = EmbeddingService.new
    self.embedding = service.embed(content)
  end

  # Returns the top N most similar chunks to the given embedding
  def self.similar_to(embedding, limit: 5)
    order(Arel.sql("embedding <-> '[#{embedding.join(',')}]' ASC")).limit(limit)
  end
end
