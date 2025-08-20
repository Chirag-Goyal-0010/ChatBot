class Api::V1::WebsitesController < Api::V1::BaseController
  before_action :sanitize_question_params, only: [:ask, :answer]
  before_action :sanitize_url_params, only: [:create]

  # GET /api/v1/websites
  def index
    websites = Website.includes(:website_chunks).all
    render_success(
      websites.map do |website|
        {
          id: website.id,
          url: website.url,
          status: website.status,
          chunks_count: website.website_chunks.count,
          created_at: website.created_at,
          updated_at: website.updated_at
        }
      end
    )
  end

  # POST /api/v1/websites
  def create
    website = Website.new(website_params)
    
    if website.save
      WebsiteScrapingJob.perform_later(website.id)
      render_success({
        id: website.id,
        url: website.url,
        status: website.status,
        message: 'Website submitted successfully! Scraping started in background.'
      }, status: :created)
    else
      render_error('Validation failed', status: :unprocessable_entity, details: website.errors)
    end
  end

  # POST /api/v1/websites/answer
  def answer
    question = params[:question]
    
    begin
      service = AnswerGenerationService.new(question)
      response = service.generate_answer
      render_success(response)
    rescue => e
      Rails.logger.error("API answer generation failed: #{e.message}")
      render_error('Failed to generate answer', status: :internal_server_error)
    end
  end

  private

  def website_params
    params.require(:website).permit(:url, :status)
  end

  def sanitize_question_params
    if params[:question].present?
      params[:question] = ActionController::Base.helpers.sanitize(
        params[:question].to_s.strip[0..1000],
        tags: [],
        attributes: []
      )
      
      if params[:question].blank?
        render_error('Please enter a valid question.', status: :bad_request)
        return
      end
    end
  end

  def sanitize_url_params
    if params[:website] && params[:website][:url].present?
      url = params[:website][:url].to_s.strip
      
      unless url.match?(/\A#{URI::regexp(['http', 'https'])}\z/)
        url = "https://#{url}" unless url.start_with?('http')
      end
      
      begin
        uri = URI.parse(url)
        if uri.host&.match?(/localhost|127\.0\.0\.1|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\./) ||
           !['http', 'https'].include?(uri.scheme)
          render_error('Invalid or restricted URL. Please use a public HTTP/HTTPS URL.', status: :bad_request)
          return
        end
        
        params[:website][:url] = uri.to_s
      rescue URI::InvalidURIError
        render_error('Invalid URL format. Please enter a valid URL.', status: :bad_request)
        return
      end
    end
  end
end
