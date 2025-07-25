require 'nokogiri'
require 'open-uri'

class NokogiriScraper
  # Scrapes the given URL and returns an array of hashes with :content and :section
  def self.scrape(url)
    html = URI.open(url).read
    doc = Nokogiri::HTML(html)

    # Remove unwanted elements
    doc.css('nav, script, footer, style, noscript, header, aside, form, iframe, .navbar, .footer').remove

    # Extract headers and paragraphs/lists
    chunks = []
    section = nil
    doc.css('h1, h2, p, li').each do |node|
      case node.name
      when 'h1', 'h2'
        section = node.text.strip
      when 'p', 'li'
        content = node.text.strip
        next if content.empty?
        chunks << { content: content, section: section }
      end
    end
    chunks
  rescue => e
    Rails.logger.error("NokogiriScraper failed: #{e.message}")
    nil
  end
end 