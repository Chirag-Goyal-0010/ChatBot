#!/usr/bin/env ruby

# Simple test script to debug scraping issues
require_relative 'config/environment'

puts "Testing scraper functionality..."

# Test 1: Basic scraper test
puts "\n1. Testing NokogiriScraper with example.com:"
begin
  result = NokogiriScraper.scrape('https://example.com')
  if result
    puts "✅ Success: #{result.count} chunks found"
    puts "First chunk: #{result.first[:content][0..100]}..." if result.any?
  else
    puts "❌ Failed: No chunks returned"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 2: Check if websites exist but have no chunks
puts "\n2. Checking existing websites:"
Website.all.each do |website|
  puts "URL: #{website.url}"
  puts "Status: #{website.status}"
  puts "Chunks: #{website.website_chunks.count}"
  puts "Error: #{website.error_message}" if website.error_message
  puts "---"
end

# Test 3: Manual scraping test
puts "\n3. Testing manual scraping process:"
begin
  test_url = 'https://httpbin.org/html'
  puts "Scraping #{test_url}..."
  
  chunks = NokogiriScraper.scrape(test_url)
  if chunks && chunks.any?
    puts "✅ Scraping successful: #{chunks.count} chunks"
    
    # Test creating a website and chunks
    website = Website.create!(url: test_url, status: 'processing')
    puts "Created website ID: #{website.id}"
    
    chunks.each_with_index do |chunk_data, idx|
      chunk = WebsiteChunk.create!(
        website: website,
        content: chunk_data[:content],
        section: chunk_data[:section] || 'General',
        position: idx
      )
      puts "Created chunk ID: #{chunk.id} with content length: #{chunk.content.length}"
    end
    
    website.update!(status: 'active')
    puts "✅ Manual process completed successfully!"
  else
    puts "❌ No chunks extracted"
  end
rescue => e
  puts "❌ Manual test failed: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\nTest completed."
