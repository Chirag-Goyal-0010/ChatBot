namespace :vector do
  desc 'Test vector functionality'
  task check: :environment do
    puts "=== Vector Functionality Test ==="
    
    # Test 1: Check if we can create a test chunk
    puts "1. Creating test chunk..."
    begin
      website = Website.first || Website.create!(url: "https://test.com", status: "active")
      chunk = WebsiteChunk.create!(
        website: website,
        content: "Test chunk for vector verification",
        section: "test"
      )
      puts "   ✅ Test chunk created with ID: #{chunk.id}"
    rescue => e
      puts "   ❌ Failed to create test chunk: #{e.message}"
      return
    end
    
    # Test 2: Check if embedding was generated
    puts "2. Checking embedding..."
    chunk.reload
    if chunk.embedding.present?
      puts "   ✅ Embedding generated successfully"
    else
      puts "   ❌ No embedding found"
    end
    
    # Test 3: Check database stats
    puts "3. Database statistics..."
    total = WebsiteChunk.count
    with_embeddings = WebsiteChunk.where.not(embedding: nil).count
    puts "   Total chunks: #{total}"
    puts "   With embeddings: #{with_embeddings}"
    
    puts "=== Test Complete ==="
  end
end 