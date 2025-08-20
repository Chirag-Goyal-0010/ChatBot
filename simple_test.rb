require 'nokogiri'
require 'open-uri'

puts "Testing basic web scraping..."

begin
  html = URI.open('https://example.com', 
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
  ).read
  
  puts "Downloaded #{html.length} bytes"
  
  doc = Nokogiri::HTML(html)
  body_text = doc.css('body').text.strip
  puts "Body text length: #{body_text.length}"
  puts "First 200 chars: #{body_text[0..200]}"
  
  # Test chunk extraction
  chunks = []
  doc.css('h1, h2, p, div').each do |node|
    text = node.text.strip
    if text.length > 20
      chunks << text
    end
  end
  
  puts "Found #{chunks.count} potential chunks"
  puts "Sample chunk: #{chunks.first}" if chunks.any?
  
rescue => e
  puts "Error: #{e.message}"
  puts e.class
end
