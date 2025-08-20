class PerformanceOptimizer
  class << self
    # Optimize database queries with eager loading and includes
    def optimize_website_queries
      # Preload associations to avoid N+1 queries
      Website.includes(:website_chunks)
    end

    def optimize_chunk_queries_with_websites
      # Eager load website data when fetching chunks
      WebsiteChunk.includes(:website)
    end

    # Batch processing for embeddings
    def batch_process_embeddings(chunk_ids, batch_size: 10)
      results = { processed: 0, failed: 0, errors: [] }
      
      WebsiteChunk.where(id: chunk_ids).find_in_batches(batch_size: batch_size) do |batch|
        batch.each do |chunk|
          begin
            service = EmbeddingService.new
            if service.insert_embedding_for_chunk(chunk)
              results[:processed] += 1
            else
              results[:failed] += 1
            end
          rescue => e
            results[:failed] += 1
            results[:errors] << { chunk_id: chunk.id, error: e.message }
          end
        end
        
        # Add small delay between batches to avoid rate limiting
        sleep(0.1) if batch_size > 5
      end
      
      results
    end

    # Optimize semantic search with caching and pagination
    def optimized_semantic_search(question, limit: 5, use_cache: true)
      return CachingService.get_cached_similar_chunks(question) if use_cache
      
      # Use database-level similarity search with proper indexing
      chunks = WebsiteChunk.similar_chunks(question, limit: limit)
      
      # Cache results for future use
      CachingService.cache_similar_chunks(question, chunks) if use_cache && chunks.any?
      
      chunks
    end

    # Background job optimization
    def optimize_background_jobs
      # Configure job priorities and queues
      {
        embedding_generation: { queue: 'high_priority', priority: 10 },
        website_scraping: { queue: 'default', priority: 5 },
        cache_warming: { queue: 'low_priority', priority: 1 }
      }
    end

    # Memory optimization for large text processing
    def process_large_content(content, chunk_size: 1000)
      return [] if content.blank?
      
      chunks = []
      content.scan(/.{1,#{chunk_size}}(?:\s|$)/m) do |chunk|
        cleaned_chunk = chunk.strip
        chunks << cleaned_chunk if cleaned_chunk.present?
      end
      
      chunks
    end

    # Database connection pool optimization
    def optimize_database_connections
      {
        pool: ENV.fetch('DB_POOL_SIZE', 10).to_i,
        checkout_timeout: 5,
        reaping_frequency: 10,
        dead_connection_timeout: 5
      }
    end

    # Query optimization helpers
    def find_chunks_with_minimal_data(limit: 100)
      # Only select necessary columns to reduce memory usage
      WebsiteChunk.select(:id, :content, :section, :website_id)
                  .includes(:website)
                  .limit(limit)
    end

    def count_chunks_by_website_efficiently
      # Use counter cache or direct SQL for better performance
      WebsiteChunk.group(:website_id).count
    end

    # Memory usage optimization
    def cleanup_unused_objects
      # Force garbage collection after heavy operations
      GC.start
      
      # Clear query cache
      ActiveRecord::Base.connection.clear_query_cache
    end

    # Performance monitoring helpers
    def benchmark_operation(operation_name)
      start_time = Time.current
      result = yield
      end_time = Time.current
      duration = end_time - start_time
      
      Rails.logger.info "[PERFORMANCE] #{operation_name} completed in #{duration.round(3)}s"
      
      # Log slow operations
      if duration > 5.0
        Rails.logger.warn "[SLOW_OPERATION] #{operation_name} took #{duration.round(3)}s - consider optimization"
      end
      
      result
    end

    # Cache warming for frequently accessed data
    def warm_critical_caches
      benchmark_operation("Cache Warming") do
        CachingService.warm_up_cache
        
        # Pre-warm frequently accessed queries
        Rails.cache.fetch('active_websites_count', expires_in: 5.minutes) do
          Website.where(status: 'active').count
        end
        
        Rails.cache.fetch('total_embeddings_count', expires_in: 5.minutes) do
          WebsiteChunk.where.not(embedding: nil).count
        end
      end
    end

    # Optimize AI service calls
    def optimize_ai_service_calls(questions)
      # Batch similar questions together
      grouped_questions = questions.group_by { |q| q.downcase.strip }
      results = {}
      
      grouped_questions.each do |normalized_question, question_variants|
        # Process once and reuse result
        result = EmbeddingService.find_similar_chunks(question_variants.first)
        question_variants.each { |q| results[q] = result }
      end
      
      results
    end
  end
end
