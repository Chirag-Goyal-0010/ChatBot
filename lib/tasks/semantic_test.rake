namespace :semantic do
  desc 'Test semantic search in isolation'
  task test: :environment do
    require_relative '../services/semantic_search_service'
    
    puts "=== Testing Semantic Search ==="
    puts
    
    # Test 1: Basic semantic search
    puts "1. Testing basic semantic search..."
    begin
      service = SemanticSearchService.new
      result = service.search("What types of products do you sell?", limit: 3)
      
      if result[:success]
        puts "   ✅ Search successful - Found #{result[:chunks].count} chunks"
        result[:chunks].each_with_index do |chunk, index|
          puts "     #{index + 1}. #{chunk.content[0..80]}..."
        end
      else
        puts "   ⚠️  Search returned no results: #{result[:message]}"
      end
    rescue => e
      puts "   ❌ Search failed: #{e.message}"
    end
    puts
    
    # Test 2: Multiple test questions
    puts "2. Testing multiple questions..."
    test_questions = [
      "What is your company about?",
      "Tell me about your services",
      "What products do you offer?",
      "How can I contact you?",
      "What are your delivery options?"
    ]
    
    test_questions.each_with_index do |question, index|
      puts "   Question #{index + 1}: #{question}"
      begin
        result = service.search(question, limit: 2)
        if result[:success]
          puts "     ✅ Found #{result[:chunks].count} relevant chunks"
        else
          puts "     ⚠️  No results: #{result[:message]}"
        end
      rescue => e
        puts "     ❌ Error: #{e.message}"
      end
    end
    puts
    
    # Test 3: Service class test method
    puts "3. Running service class tests..."
    begin
      test_results = SemanticSearchService.test_search
      test_results.each do |test|
        status = test[:success] ? "✅" : "❌"
        puts "   #{status} '#{test[:question]}' - #{test[:chunk_count]} chunks"
      end
    rescue => e
      puts "   ❌ Service test failed: #{e.message}"
    end
    puts
    
    puts "=== Semantic Search Testing Complete ==="
  end
  
  desc 'Test semantic search with specific question'
  task :test_question, [:question] => :environment do |task, args|
    require_relative '../services/semantic_search_service'
    
    question = args[:question] || "What types of products do you sell?"
    puts "Testing semantic search with question: '#{question}'"
    puts
    
    begin
      service = SemanticSearchService.new
      result = service.search_with_content(question, limit: 5)
      
      if result[:success]
        puts "✅ Found #{result[:chunks].count} relevant chunks:"
        puts
        result[:chunks].each_with_index do |chunk, index|
          puts "#{index + 1}. Content: #{chunk[:content]}"
          puts "   Section: #{chunk[:section]}"
          puts "   Website: #{chunk[:website_url]}"
          puts
        end
      else
        puts "❌ #{result[:message]}"
      end
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
end 