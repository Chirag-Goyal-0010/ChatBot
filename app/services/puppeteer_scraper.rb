require 'puppeteer-ruby'
require 'nokogiri'
require 'retries'
require 'timeout'

class PuppeteerScraper
  TIMEOUT_SECONDS = 60
  MAX_RETRIES = 2
  RETRY_DELAY = 2
  
  # Scrapes the given URL and returns an array of hashes with :content and :section
  def self.scrape(url)
    with_retries(
      max_tries: MAX_RETRIES,
      base_sleep_seconds: RETRY_DELAY,
      max_sleep_seconds: 5,
      rescue: [Timeout::Error, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED, Puppeteer::TimeoutError]
    ) do
      Timeout::timeout(TIMEOUT_SECONDS) do
        chunks = []
        section = nil
        Puppeteer.launch(headless: true, timeout: 30000) do |browser|
          page = browser.new_page
          page.default_timeout = 30000
          page.goto(url, wait_until: 'networkidle2', timeout: 30000)
          html = page.content
          doc = Nokogiri::HTML(html)
          doc.css('nav, script, footer, style, noscript, header, aside, form, iframe, .navbar, .footer').remove
          
          # Extract all text content more broadly
          doc.css('h1, h2, h3, p, li, div, span, article, section').each do |node|
            text = node.text.strip
            next if text.empty? || text.length < 10
            
            case node.name
            when 'h1', 'h2', 'h3'
              section = text
            when 'p', 'li', 'div', 'span', 'article', 'section'
              # Only add if it's substantial content
              if text.length > 20 && !text.match?(/^(menu|navigation|footer|header)/i)
                chunks << { content: text, section: section }
              end
            end
          end
          
          # If no chunks found, try extracting from body text
          if chunks.empty?
            body_text = doc.css('body').text.strip
            if body_text.present? && body_text.length > 50
              # Split into paragraphs
              paragraphs = body_text.split(/\n\s*\n/).map(&:strip).reject(&:blank?)
              paragraphs.each do |para|
                next if para.length < 20
                chunks << { content: para, section: 'General' }
              end
            end
          end
        end
        chunks
      end
    end
  rescue Timeout::Error => e
    Rails.logger.error("PuppeteerScraper timeout for #{url}: #{e.message}")
    nil
  rescue Puppeteer::TimeoutError => e
    Rails.logger.error("Puppeteer timeout for #{url}: #{e.message}")
    nil
  rescue => e
    Rails.logger.error("PuppeteerScraper failed after #{MAX_RETRIES} retries for #{url}: #{e.message}")
    nil
  end
end
