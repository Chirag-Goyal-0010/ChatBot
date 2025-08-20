class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    # Add index on website status for filtering
    add_index :websites, :status
    
    # Add index on website_chunks position for ordering
    add_index :website_chunks, :position
    
    # Add index on website_chunks section for filtering
    add_index :website_chunks, :section
    
    # Add composite index for website_chunks queries
    add_index :website_chunks, [:website_id, :position]
    
    # Add index on created_at for both tables for time-based queries
    add_index :websites, :created_at
    add_index :website_chunks, :created_at

    # Vector index for efficient similarity search (cosine distance)
    # Requires pgvector extension and pgvector gem
    if vector_extension_available?
      execute <<~SQL
        CREATE INDEX IF NOT EXISTS index_website_chunks_on_embedding_vector_cosine
        ON website_chunks
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 100);
      SQL
    else
      Rails.logger.warn "pgvector extension not available - skipping vector index creation"
    end
  end
  
  private
  
  def vector_extension_available?
    # Check if the vector extension is enabled
    connection.execute("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
  rescue => e
    Rails.logger.warn "Could not check for vector extension: #{e.message}"
    false
  end
end 