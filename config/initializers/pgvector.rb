# Ensure Active Record knows about the pgvector type
begin
  require 'pgvector'
  
  # Register the vector type with Active Record if the class exists
  if defined?(Pgvector::VectorType)
    ActiveRecord::Type.register(:vector, Pgvector::VectorType)
  end
  
rescue LoadError => e
  Rails.logger.warn "pgvector gem not available: #{e.message}"
end


