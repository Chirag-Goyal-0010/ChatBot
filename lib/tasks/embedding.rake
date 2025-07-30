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

  desc 'Embed all previously scraped WebsiteChunk records'
  task embed_all: :environment do
    require_relative '../../app/models/website_chunk'
    require_relative '../services/embedding_service'

    puts "=== Embedding All WebsiteChunks ==="
    
    # Get chunks without embeddings
    chunks_without_embeddings = WebsiteChunk.where(embedding: nil)
    total_chunks = chunks_without_embeddings.count
    
    if total_chunks == 0
      puts "✅ All chunks already have embeddings!"
      next
    end
    
    puts "Found #{total_chunks} chunks without embeddings. Starting batch processing..."
    
    # Process in batches
    results = EmbeddingService.batch_embed_chunks(chunks_without_embeddings)
    
    puts "=== Results ==="
    puts "✅ Successfully embedded: #{results[:success]} chunks"
    puts "❌ Failed to embed: #{results[:failed]} chunks"
    
    if results[:errors].any?
      puts "\nErrors:"
      results[:errors].each { |error| puts "  - #{error}" }
    end
    
    puts "\n=== Embedding Complete ==="
  end
end 