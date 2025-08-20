# frozen_string_literal: true

class Rack::Attack
  # Configure Redis for rate limiting (optional, uses memory by default)
  # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new

  # Allow localhost and private IPs during development
  safelist('allow-localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip || req.ip.start_with?('192.168.', '10.', '172.')
  end

  # Throttle general requests by IP
  throttle('requests/ip', limit: 100, period: 1.hour) do |req|
    req.ip
  end

  # Throttle AI question requests more strictly
  throttle('ai-questions/ip', limit: 20, period: 1.hour) do |req|
    req.ip if req.path.match?(/\/websites\/(ask|answer)/) && req.post?
  end

  # Throttle website scraping requests
  throttle('scraping/ip', limit: 10, period: 1.hour) do |req|
    req.ip if req.path == '/websites' && req.post?
  end

  # Block requests with suspicious patterns
  blocklist('block-suspicious-requests') do |req|
    # Block requests with suspicious user agents
    req.user_agent&.match?(/bot|crawler|spider|scraper/i) &&
      !req.user_agent&.match?(/googlebot|bingbot/i)
  end

  # Exponential backoff for repeated failures
  throttle('login-failures/ip', limit: 5, period: 20.minutes) do |req|
    req.ip if req.path == '/login' && req.post?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]
    
    headers = {
      'Content-Type' => 'application/json',
      'Retry-After' => match_data[:period].to_s,
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + match_data[:period]).to_s
    }
    
    body = {
      error: 'Rate limit exceeded',
      message: 'Too many requests. Please try again later.',
      retry_after: match_data[:period]
    }.to_json
    
    [429, headers, [body]]
  end

  # Log blocked and throttled requests
  ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] #{name}: #{req.ip} #{req.request_method} #{req.fullpath}"
  end
end
