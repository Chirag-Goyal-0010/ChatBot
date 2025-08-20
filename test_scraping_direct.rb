#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== Testing Direct Scraping ==="

# Test the scraper directly
url = 'https://example.com'
puts "Testing: #{url}"

begin
  chunks = NokogiriScraper.scrape(url)
  if chunks && chunks.any?
    puts "✓ SUCCESS: Found #{chunks.count} chunks"
    puts "Sample: #{chunks.first[:content][0..100]}..."
  else
    puts "✗ FAILED: No chunks returned"
  end
rescue => e
  puts "✗ ERROR: #{e.message}"
  puts e.backtrace.first(3)
end

# Test job execution directly
puts "\n=== Testing Job Execution ==="
begin
  website = Website.create!(url: 'https://httpbin.org/html')
  puts "Created website ID: #{website.id}"
  
  WebsiteScrapingJob.perform_now(website.id)
  
  website.reload
  puts "Status: #{website.status}"
  puts "Chunks: #{website.website_chunks.count}"
  
  if website.website_chunks.any?
    puts "✓ SUCCESS: Job created chunks"
  else
    puts "✗ FAILED: Job created no chunks"
    puts "Error: #{website.error_message}" if website.error_message
  end
rescue => e
  puts "✗ JOB ERROR: #{e.message}"
  puts e.backtrace.first(5)
end
