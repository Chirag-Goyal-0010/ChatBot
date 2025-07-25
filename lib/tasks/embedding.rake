namespace :embedding do
  desc 'Generate embeddings for all WebsiteChunks without embeddings'
  task generate: :environment do
    require_relative '../../app/models/website_chunk'
    require_relative '../services/embedding_service'

    WebsiteChunk.where(embedding: nil).find_each do |chunk|
      puts "Generating embedding for chunk ##{chunk.id}..."
      chunk.save! # triggers before_save callback
    end
    puts 'Embedding generation complete.'
  end
end 