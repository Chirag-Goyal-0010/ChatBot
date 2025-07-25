require Rails.root.join('lib', 'services', 'nokogiri_scraper')
require Rails.root.join('lib', 'services', 'puppeteer_scraper')

class WebsitesController < ApplicationController
  def new
    @website = Website.new
  end

  def create
    @website = Website.new(website_params)
    if @website.save
      flash[:notice] = 'Website URL submitted successfully! Scraping in progress...'
      # Start scraping synchronously
      chunks = NokogiriScraper.scrape(@website.url)
      if chunks.nil? || chunks.empty?
        chunks = PuppeteerScraper.scrape(@website.url)
        flash[:alert] = 'Static scraping failed, used dynamic scraping.' if chunks
      end
      if chunks && !chunks.empty?
        chunks.each_with_index do |chunk, idx|
          WebsiteChunk.create!(website: @website, content: chunk[:content], section: chunk[:section], position: idx)
        end
        flash[:notice] = 'Scraping completed and content saved.'
      else
        flash[:alert] = 'Scraping failed for this website.'
        Rails.logger.error("Scraping failed for website ID: #{@website.id}, URL: #{@website.url}")
      end
      redirect_to websites_path
    else
      flash.now[:alert] = 'Invalid URL. Please try again.'
      render :new
    end
  end

  def index
    @websites = Website.all
  end

  # POST /websites/ask
  def ask
    question = params[:question]
    @chunks = EmbeddingService.find_similar_chunks(question, limit: 5)
    if @chunks.nil?
      flash.now[:alert] = "I don't have information to answer that question."
    end
    render :ask_result
  end

  private

  def website_params
    params.require(:website).permit(:url, :status)
  end
end
