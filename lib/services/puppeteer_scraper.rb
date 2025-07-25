require 'puppeteer-ruby'

class PuppeteerScraper
  # Scrapes the given URL and returns an array of hashes with :content and :section
  def self.scrape(url)
    chunks = []
    section = nil
    Puppeteer.launch(headless: true) do |browser|
      page = browser.new_page
      page.goto(url, wait_until: 'networkidle2')
      html = page.content
      doc = Nokogiri::HTML(html)
      doc.css('nav, script, footer, style, noscript, header, aside, form, iframe, .navbar, .footer').remove
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
    end
    chunks
  rescue => e
    Rails.logger.error("PuppeteerScraper failed: #{e.message}")
    nil
  end
end 