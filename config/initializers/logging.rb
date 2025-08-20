# Enhanced logging configuration
Rails.application.configure do
  # Custom log formatter
  config.log_formatter = proc do |severity, datetime, progname, msg|
    formatted_datetime = datetime.strftime("%Y-%m-%d %H:%M:%S.%3N")
    "[#{formatted_datetime}] #{severity} -- #{progname}: #{msg}\n"
  end

  # Log level based on environment
  config.log_level = case Rails.env
                     when 'production'
                       :info
                     when 'staging'
                       :debug
                     else
                       :debug
                     end

  # Structured logging for important events
  config.after_initialize do
    # Log AI service interactions
    ActiveSupport::Notifications.subscribe('ai_service.embedding') do |name, started, finished, unique_id, data|
      duration = finished - started
      Rails.logger.info "[AI_SERVICE] Embedding generated for chunk_id=#{data[:chunk_id]} duration=#{duration.round(3)}s"
    end

    ActiveSupport::Notifications.subscribe('ai_service.question') do |name, started, finished, unique_id, data|
      duration = finished - started
      Rails.logger.info "[AI_SERVICE] Question processed question_length=#{data[:question]&.length} chunks_found=#{data[:chunks_count]} duration=#{duration.round(3)}s"
    end

    # Log scraping activities
    ActiveSupport::Notifications.subscribe('scraping.website') do |name, started, finished, unique_id, data|
      duration = finished - started
      Rails.logger.info "[SCRAPING] Website scraped url=#{data[:url]} chunks_created=#{data[:chunks_count]} method=#{data[:method]} duration=#{duration.round(3)}s"
    end

    # Log rate limiting events
    ActiveSupport::Notifications.subscribe('rack_attack') do |name, started, finished, unique_id, data|
      req = data[:request]
      Rails.logger.warn "[RATE_LIMIT] #{name} ip=#{req.ip} path=#{req.path} user_agent=#{req.user_agent&.truncate(100)}"
    end
  end
end

# Custom logger for AI operations
class AILogger
  def self.log_embedding_generation(chunk_id, success, duration = nil, error = nil)
    if success
      Rails.logger.info "[AI_EMBEDDING] SUCCESS chunk_id=#{chunk_id} duration=#{duration&.round(3)}s"
    else
      Rails.logger.error "[AI_EMBEDDING] FAILED chunk_id=#{chunk_id} error=#{error&.message}"
    end
  end

  def self.log_question_processing(question, chunks_found, success, duration = nil, error = nil)
    question_preview = question&.truncate(50)
    if success
      Rails.logger.info "[AI_QUESTION] SUCCESS question='#{question_preview}' chunks=#{chunks_found} duration=#{duration&.round(3)}s"
    else
      Rails.logger.error "[AI_QUESTION] FAILED question='#{question_preview}' error=#{error&.message}"
    end
  end

  def self.log_scraping_activity(url, method, chunks_count, success, duration = nil, error = nil)
    if success
      Rails.logger.info "[SCRAPING] SUCCESS url=#{url} method=#{method} chunks=#{chunks_count} duration=#{duration&.round(3)}s"
    else
      Rails.logger.error "[SCRAPING] FAILED url=#{url} method=#{method} error=#{error&.message}"
    end
  end
end
