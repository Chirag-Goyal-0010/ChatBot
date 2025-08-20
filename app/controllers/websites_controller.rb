require 'timeout'

class WebsitesController < ApplicationController
  before_action :sanitize_question_params, only: [:ask, :answer]
  before_action :sanitize_url_params, only: [:create]
  def new
    @website = Website.new
  end

  def create
    @website = Website.new(website_params)
    
    if @website.save
      # Start background scraping job
      WebsiteScrapingJob.perform_later(@website.id)
      flash[:notice] = 'Website URL submitted successfully! Scraping has started in the background.'
      redirect_to websites_path
    else
      standardized_error_response('Invalid URL. Please try again.', details: @website.errors)
    end
  end

  def index
    @websites = Website.all
    if params[:question].present? && params[:chunks].present?
      @chunks = WebsiteChunk.where(id: params[:chunks].split(','))
    end
  end

  # POST /websites/ask
  def ask
    question = params[:question]
    @chunks = EmbeddingService.find_similar_chunks(question, limit: 5)
    if @chunks.nil?
      flash.now[:alert] = "I don't have information to answer that question."
    end
    redirect_to websites_path(question: question, chunks: @chunks&.pluck(:id))
  end

  # GET/POST /websites/answer - AI-powered answer endpoint
  def answer
    if request.get?
      # GET request - show the form
      @answer = {
        question: "",
        answer: "",
        chunks: [],
        success: false
      }
      render :answer
      return
    end
    
    # POST request - process the question
    question = params[:question]
    
    begin
      # Use the service to generate the answer
      service = AnswerGenerationService.new(question)
      @answer = service.generate_answer
    rescue => e
      Rails.logger.error("Answer generation failed: #{e.message}")
      @answer = {
        question: question,
        answer: "Sorry, I encountered an error while processing your question. Please try again in a moment.",
        chunks: [],
        success: false
      }
    end
    
    respond_to do |format|
      format.html { render :answer }
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.replace("ai-response", partial: "ai_answer", locals: { answer: @answer }),
          turbo_stream.update("loading-indicator", ""),
          turbo_stream.update("question-input", "")
        ]
      }
      format.json { render json: @answer }
    end
  end

  private

  def website_params
    params.require(:website).permit(:url, :status)
  end

  def sanitize_question_params
    if params[:question].present?
      # Remove potentially harmful characters and limit length
      params[:question] = ActionController::Base.helpers.sanitize(
        params[:question].to_s.strip[0..1000],
        tags: [],
        attributes: []
      )
      
      # Block if question is empty after sanitization
      if params[:question].blank?
        standardized_error_response("Please enter a valid question.")
        return
      end
    end
  end

  def sanitize_url_params
    if params[:website] && params[:website][:url].present?
      url = params[:website][:url].to_s.strip
      
      # Basic URL validation and sanitization
      unless url.match?(/\A#{URI::regexp(['http', 'https'])}\z/)
        # Try to fix common URL issues
        url = "https://#{url}" unless url.start_with?('http')
      end
      
      # Additional security checks
      begin
        uri = URI.parse(url)
        # Block localhost, private IPs, and suspicious schemes
        if uri.host&.match?(/localhost|127\.0\.0\.1|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\./) ||
           !['http', 'https'].include?(uri.scheme)
          standardized_error_response("Invalid or restricted URL. Please use a public HTTP/HTTPS URL.")
          return
        end
        
        params[:website][:url] = uri.to_s
      rescue URI::InvalidURIError
        standardized_error_response("Invalid URL format. Please enter a valid URL.")
        return
      end
    end
  end
end
