namespace :embedding do
  desc 'Generate embeddings for all WebsiteChunks without embeddings'
  task generate: :environment do
    require_relative '../../app/models/website_chunk'
    require_relative '../services/embedding_service'

    chunks = WebsiteChunk.where(embedding: nil)
    if chunks.count.zero?
      puts 'No chunks need embeddings.'
      next
    end

    puts "Generating embeddings for #{chunks.count} chunks..."
    results = EmbeddingService.batch_embed_chunks(chunks)
    puts "Done. Success: #{results[:success]}, Failed: #{results[:failed]}"
    if results[:errors].any?
      puts 'Errors:'
      results[:errors].each { |e| puts "  - #{e}" }
    end
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