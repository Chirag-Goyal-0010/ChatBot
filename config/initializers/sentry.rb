Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set tracing sample rate
  config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0
  
  # Filter sensitive data
  config.before_send = lambda do |event, hint|
    # Filter out sensitive parameters
    if event.request&.data
      event.request.data = event.request.data.except('password', 'password_confirmation', 'api_key')
    end
    
    # Don't send events for certain errors in development
    if Rails.env.development? && event.exception&.values&.any? { |ex| ex[:type] == 'ActionController::RoutingError' }
      nil
    else
      event
    end
  end

  # Set release version
  config.release = ENV['HEROKU_SLUG_COMMIT'] || `git rev-parse HEAD`.strip rescue 'unknown'
  
  # Set environment
  config.environment = Rails.env
  
  # Performance monitoring
  config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0
end
