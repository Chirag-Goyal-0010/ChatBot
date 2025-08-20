class AddEmbeddingToWebsiteChunks < ActiveRecord::Migration[8.0]
  def change
    # Check if vector type is available
    if vector_type_available?
      add_column :website_chunks, :embedding, :vector, limit: 1536
    else
      # Fallback to text column for now
      add_column :website_chunks, :embedding, :text
      Rails.logger.warn "Vector type not available - using text column for embeddings"
    end
  end
  
  private
  
  def vector_type_available?
    # Check if the vector extension is enabled
    connection.execute("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
  rescue => e
    Rails.logger.warn "Could not check for vector extension: #{e.message}"
    false
  end
end
