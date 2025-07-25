class AddEmbeddingToWebsiteChunks < ActiveRecord::Migration[7.0]
  def change
    add_column :website_chunks, :embedding, :vector, limit: 1536
  end
end
