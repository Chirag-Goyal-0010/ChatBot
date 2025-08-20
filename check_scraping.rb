#!/usr/bin/env ruby

# Simple diagnostic script to test scraping without Rails overhead
require 'nokogiri'
require 'open-uri'
require 'openssl'

puts "=== Scraping Diagnostic Test ==="

def test_scrape(url)
  puts "\nTesting: #{url}"
  
  begin
    # Test basic HTTP connection
    html = URI.open(url, 
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
      read_timeout: 10
    ).read
    
    puts "✓ Downloaded #{html.length} bytes"
    
    # Parse HTML
    doc = Nokogiri::HTML(html)
    
    # Remove unwanted elements
    doc.css('nav, script, footer, style, noscript, header, aside, form, iframe').remove
    
    # Extract content
    chunks = []
    section = 'General'
    
    doc.css('h1, h2, h3, p, li, div, span, article, section').each do |node|
      text = node.text.strip
      next if text.empty? || text.length < 10
      
      case node.name
      when 'h1', 'h2', 'h3'
        section = text
      when 'p', 'li', 'div', 'span', 'article', 'section'
        if text.length > 20 && !text.match?(/^(menu|navigation|footer|header)/i)
          chunks << { content: text, section: section }
        end
      end
    end
    
    # Fallback to body text if no chunks
    if chunks.empty?
      body_text = doc.css('body').text.strip
      if body_text.length > 50
        paragraphs = body_text.split(/\n\s*\n/).map(&:strip).reject(&:empty?)
        paragraphs.each do |para|
          next if para.length < 20
          chunks << { content: para, section: 'General' }
        end
      end
    end
    
    puts "✓ Extracted #{chunks.count} chunks"
    if chunks.any?
      puts "Sample chunk: #{chunks.first[:content][0..100]}..."
    else
      puts "✗ No chunks extracted - content might be dynamic or blocked"
    end
    
  rescue => e
    puts "✗ Error: #{e.class} - #{e.message}"
  end
end

# Test different URLs
test_scrape('https://example.com')
test_scrape('https://httpbin.org/html')

puts "\n=== Test Complete ==="
