class ApplicationController < ActionController::Base
  include ErrorHandling
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :validate_openai_configuration
  
  private
  
  def validate_openai_configuration
    unless ENV['OPENAI_API_KEY'].present?
      respond_to do |format|
        format.html { 
          flash[:alert] = "OpenAI API key not configured. Please contact administrator."
          redirect_to root_path
        }
        format.json { 
          render json: {
            success: false,
            error: "OpenAI API key not configured",
            timestamp: Time.current.to_i
          }, status: :service_unavailable
        }
      end
    end
  end
  
  def standardized_error_response(message, details: nil, status: :unprocessable_entity)
    error_data = {
      error: true,
      message: message,
      timestamp: Time.current.iso8601
    }
    error_data[:details] = details if details.present?
    
    respond_to do |format|
      format.html { 
        flash[:alert] = message
        redirect_back(fallback_location: root_path)
      }
      format.json { render json: error_data, status: status }
    end
  end
end
