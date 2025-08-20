#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== Testing Scraper Functionality ==="

# Test the scraper directly
puts "\n1. Testing NokogiriScraper with example.com:"
begin
  chunks = NokogiriScraper.scrape('https://example.com')
  if chunks
    puts "✓ Found #{chunks.count} chunks"
    puts "First chunk: #{chunks.first.inspect}" if chunks.any?
  else
    puts "✗ Scraper returned nil"
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test a simple website
puts "\n2. Testing with httpbin.org/html:"
begin
  chunks = NokogiriScraper.scrape('https://httpbin.org/html')
  if chunks
    puts "✓ Found #{chunks.count} chunks"
    puts "First chunk: #{chunks.first.inspect}" if chunks.any?
  else
    puts "✗ Scraper returned nil"
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test job execution
puts "\n3. Testing WebsiteScrapingJob:"
begin
  website = Website.create!(url: 'https://example.com')
  puts "Created website ID: #{website.id}"
  
  # Run the job directly
  WebsiteScrapingJob.perform_now(website.id)
  
  website.reload
  puts "Website status: #{website.status}"
  puts "Chunks count: #{website.website_chunks.count}"
  
  if website.website_chunks.any?
    puts "✓ Chunks created successfully!"
    puts "Sample chunk: #{website.website_chunks.first.content[0..100]}..."
  else
    puts "✗ No chunks created"
    puts "Error message: #{website.error_message}" if website.error_message
  end
rescue => e
  puts "✗ Job error: #{e.message}"
  puts e.backtrace.first(5)
end
