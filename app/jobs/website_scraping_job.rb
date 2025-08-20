class WebsiteScrapingJob < ApplicationJob
  queue_as :default
  
  # Resource limits
  MAX_CHUNKS_PER_WEBSITE = 500
  MAX_CHUNK_SIZE = 2000
  MAX_SECTION_LENGTH = 200
  
  # Job retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(website_id)
    website = Website.find(website_id)
    
    begin
      Rails.logger.info("WebsiteScrapingJob: Starting scrape for website ID #{website_id}, URL: #{website.url}")
      
      # Check OpenAI API key early but don't fail scraping if missing
      if ENV['OPENAI_API_KEY'].blank?
        Rails.logger.warn("WebsiteScrapingJob: OpenAI API key not configured - embeddings will be skipped")
      end
      
      website.update!(status: 'processing')
      
      # Try static scraping first
      chunks = NokogiriScraper.scrape(website.url)
      Rails.logger.info("WebsiteScrapingJob: Static scraping returned #{chunks ? chunks.count : 'nil'} chunks")
      
      # Skip dynamic scraping to avoid hanging - use static only for now
      if chunks.nil? || chunks.empty?
        Rails.logger.info("WebsiteScrapingJob: Static scraping failed, skipping dynamic scraping to avoid hanging")
      end
      
      if chunks && !chunks.empty?
        # Apply resource limits
        limited_chunks = apply_resource_limits(chunks)
        
        # Create chunks and generate embeddings with controlled batching
        limited_chunks.each_with_index do |chunk_data, idx|
          chunk = WebsiteChunk.create!(
            website: website,
            content: chunk_data[:content],
            section: chunk_data[:section],
            position: idx
          )
          
          # Only queue embedding jobs if OpenAI API key is available
          if ENV['OPENAI_API_KEY'].present?
            # Use perform_now for inline processing in development
            EmbeddingJob.perform_now(chunk.id)
          else
            Rails.logger.info("Skipping embedding generation - no OpenAI API key configured")
          end
        end
        
        website.mark_scraping_complete!
        Rails.logger.info("Successfully scraped #{limited_chunks.count} chunks from #{website.url}")
      else
        website.mark_scraping_failed!('No content could be extracted')
        Rails.logger.error("Scraping failed for website ID: #{website.id}, URL: #{website.url}")
      end
    rescue => e
      error_message = "Scraping failed: #{e.message}"
      website.mark_scraping_failed!(error_message)
      Rails.logger.error("Scraping job failed for website #{website.id}: #{e.message}")
      
      # Only raise if this is the final attempt
      raise e if executions >= self.class.retry_attempts
    end
  end
  
  private
  
  def apply_resource_limits(chunks)
    # Limit number of chunks
    limited_chunks = chunks.first(MAX_CHUNKS_PER_WEBSITE)
    
    # Apply size limits to each chunk
    limited_chunks.map do |chunk_data|
      {
        content: chunk_data[:content]&.truncate(MAX_CHUNK_SIZE) || '',
        section: chunk_data[:section] || 'General'
      }
    end.reject { |chunk| chunk[:content].blank? || chunk[:content].length < 10 }
  end
end