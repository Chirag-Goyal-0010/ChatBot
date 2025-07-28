require Rails.root.join('lib', 'services', 'embedding_service')

namespace :vectors do
  desc 'Test vector storage and retrieval functionality'
  task verify: :environment do
    puts "=== Testing Vector Storage and Retrieval ==="
    puts
    
    # Test 1: EmbeddingService
    puts "1. Testing EmbeddingService..."
    service_result = EmbeddingService.test_service
    if service_result[:success]
      puts "   ✅ EmbeddingService working - Length: #{service_result[:embedding_length]}, Dimensions match: #{service_result[:dimensions_match]}"
    else
      puts "   ❌ EmbeddingService failed: #{service_result[:error]}"
      return
    end
    puts
    
    # Test 2: Vector storage in WebsiteChunk
    puts "2. Testing WebsiteChunk vector storage..."
    begin
      chunk_result = WebsiteChunk.test_vector_storage
      if chunk_result[:has_embedding]
        puts "   ✅ Vector stored successfully - ID: #{chunk_result[:id]}, Length: #{chunk_result[:embedding_length]}"
      else
        puts "   ❌ Vector storage failed"
        return
      end
    rescue => e
      puts "   ❌ Vector storage test failed: #{e.message}"
      return
    end
    puts
    
    # Test 3: Similarity search
    puts "3. Testing similarity search..."
    begin
      test_question = "What is this test about?"
      similar_chunks = EmbeddingService.find_similar_chunks(test_question, limit: 3)
      if similar_chunks
        puts "   ✅ Similarity search working - Found #{similar_chunks.count} chunks"
        similar_chunks.each_with_index do |chunk, index|
          puts "     #{index + 1}. #{chunk.content[0..50]}..."
        end
      else
        puts "   ⚠️  Similarity search returned no results (this might be normal)"
      end
    rescue => e
      puts "   ❌ Similarity search failed: #{e.message}"
    end
    puts
    
    # Test 4: Database statistics
    puts "4. Database statistics..."
    total_chunks = WebsiteChunk.count
    chunks_with_embeddings = WebsiteChunk.where.not(embedding: nil).count
    puts "   Total chunks: #{total_chunks}"
    puts "   Chunks with embeddings: #{chunks_with_embeddings}"
    puts "   Embedding coverage: #{(chunks_with_embeddings.to_f / total_chunks * 100).round(1)}%"
    puts
    
    puts "=== Vector Testing Complete ==="
  end
  
  desc 'Create test data for vector testing'
  task create_test_data: :environment do
    puts "Creating test data for vector testing..."
    
    # Create a test website
    website = Website.find_or_create_by(url: "https://test-vectors.com") do |w|
      w.status = "active"
    end
    
    # Create test chunks
    test_contents = [
      "This is a test chunk about artificial intelligence and machine learning.",
      "Another test chunk discussing web development and programming languages.",
      "A third test chunk covering database systems and vector storage.",
      "Test chunk about natural language processing and text embeddings.",
      "Final test chunk about software engineering best practices."
    ]
    
    test_contents.each_with_index do |content, index|
      WebsiteChunk.find_or_create_by(
        website: website,
        content: content,
        section: "test-section-#{index + 1}",
        position: index
      )
    end
    
    puts "Created #{test_contents.length} test chunks"
  end
end 