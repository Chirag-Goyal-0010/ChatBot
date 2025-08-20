class Api::V1::BaseController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
  
  # Always respond with JSON for API endpoints
  respond_to :json
  
  private
  
  def render_success(data, status: :ok)
    render json: {
      success: true,
      data: data,
      timestamp: Time.current.to_i
    }, status: status
  end
  
  def render_error(message, status: :bad_request, details: nil)
    render json: {
      success: false,
      error: message,
      details: details,
      timestamp: Time.current.to_i
    }, status: status
  end
end
