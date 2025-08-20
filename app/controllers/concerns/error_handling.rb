module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from OpenAI::Error, with: :handle_openai_error
    rescue_from Timeout::Error, with: :handle_timeout_error
  end

  private

  def handle_standard_error(exception)
    Rails.logger.error "StandardError: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    respond_to do |format|
      format.html do
        flash[:alert] = "An unexpected error occurred. Please try again."
        redirect_to root_path
      end
      format.json { render json: { error: "Internal server error" }, status: 500 }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash-messages", 
          partial: "shared/flash", locals: { flash: { alert: "An unexpected error occurred. Please try again." } })
      end
    end
  end

  def handle_not_found(exception)
    Rails.logger.warn "Record not found: #{exception.message}"
    
    respond_to do |format|
      format.html do
        flash[:alert] = "The requested resource was not found."
        redirect_to root_path
      end
      format.json { render json: { error: "Resource not found" }, status: 404 }
    end
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn "Parameter missing: #{exception.message}"
    
    respond_to do |format|
      format.html do
        flash[:alert] = "Required information is missing. Please try again."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Missing required parameters" }, status: 400 }
    end
  end

  def handle_openai_error(exception)
    Rails.logger.error "OpenAI API Error: #{exception.message}"
    
    error_message = case exception
    when OpenAI::RateLimitError
      "AI service is temporarily busy. Please try again in a moment."
    when OpenAI::AuthenticationError
      "AI service configuration error. Please contact support."
    else
      "AI service is temporarily unavailable. Please try again later."
    end
    
    respond_to do |format|
      format.html do
        flash[:alert] = error_message
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: error_message }, status: 503 }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("ai-response", 
          partial: "shared/error_message", locals: { message: error_message })
      end
    end
  end

  def handle_timeout_error(exception)
    Rails.logger.warn "Timeout Error: #{exception.message}"
    
    respond_to do |format|
      format.html do
        flash[:alert] = "The request took too long to process. Please try again."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Request timeout" }, status: 408 }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("ai-response", 
          partial: "shared/error_message", locals: { message: "Request timed out. Please try again." })
      end
    end
  end
end
