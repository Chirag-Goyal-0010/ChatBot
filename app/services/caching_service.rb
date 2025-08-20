require 'digest'

class CachingService
  # Cache keys
  QUESTION_CACHE_KEY = 'ai_answer'
  EMBEDDING_CACHE_KEY = 'embedding'
  SIMILAR_CHUNKS_CACHE_KEY = 'similar_chunks'
  WEBSITE_STATUS_CACHE_KEY = 'website_status'

  # Cache expiration times
  QUESTION_CACHE_EXPIRY = 1.hour
  EMBEDDING_CACHE_EXPIRY = 24.hours
  SIMILAR_CHUNKS_CACHE_EXPIRY = 30.minutes
  WEBSITE_STATUS_CACHE_EXPIRY = 5.minutes

  class << self
    # Cache AI answers for repeated questions
    def cache_ai_answer(question, answer_data)
      cache_key = generate_question_cache_key(question)
      Rails.cache.write(cache_key, answer_data, expires_in: QUESTION_CACHE_EXPIRY)
    end

    def get_cached_ai_answer(question)
      cache_key = generate_question_cache_key(question)
      Rails.cache.read(cache_key)
    end

    # Cache embeddings to avoid regenerating
    def cache_embedding(text, embedding)
      cache_key = generate_embedding_cache_key(text)
      Rails.cache.write(cache_key, embedding, expires_in: EMBEDDING_CACHE_EXPIRY)
    end

    def get_cached_embedding(text)
      cache_key = generate_embedding_cache_key(text)
      Rails.cache.read(cache_key)
    end

    # Cache similar chunks results
    def cache_similar_chunks(question, chunks)
      cache_key = generate_similar_chunks_cache_key(question)
      chunk_data = chunks.map do |chunk|
        {
          id: chunk.id,
          content: chunk.content,
          section: chunk.section,
          website_id: chunk.website_id,
          position: chunk.position
        }
      end
      Rails.cache.write(cache_key, chunk_data, expires_in: SIMILAR_CHUNKS_CACHE_EXPIRY)
    end

    def get_cached_similar_chunks(question)
      cache_key = generate_similar_chunks_cache_key(question)
      cached_data = Rails.cache.read(cache_key)
      
      return nil unless cached_data
      
      # Reconstruct chunk objects from cached data
      chunk_ids = cached_data.map { |chunk| chunk[:id] }
      WebsiteChunk.where(id: chunk_ids).order("CASE id #{chunk_ids.map.with_index { |id, i| "WHEN #{id} THEN #{i}" }.join(' ')} END")
    end

    # Cache website status counts
    def cache_website_status_counts(counts)
      Rails.cache.write(WEBSITE_STATUS_CACHE_KEY, counts, expires_in: WEBSITE_STATUS_CACHE_EXPIRY)
    end

    def get_cached_website_status_counts
      Rails.cache.read(WEBSITE_STATUS_CACHE_KEY)
    end

    # Cache invalidation methods
    def invalidate_question_cache(question = nil)
      if question
        cache_key = generate_question_cache_key(question)
        Rails.cache.delete(cache_key)
      else
        # Clear all question caches (use pattern matching if supported)
        Rails.cache.delete_matched("#{QUESTION_CACHE_KEY}:*") if Rails.cache.respond_to?(:delete_matched)
      end
    end

    def invalidate_website_caches
      Rails.cache.delete(WEBSITE_STATUS_CACHE_KEY)
      Rails.cache.delete_matched("#{SIMILAR_CHUNKS_CACHE_KEY}:*") if Rails.cache.respond_to?(:delete_matched)
    end

    def invalidate_embedding_cache(text)
      cache_key = generate_embedding_cache_key(text)
      Rails.cache.delete(cache_key)
    end

    # Warm up cache with frequently accessed data
    def warm_up_cache
      # Cache website status counts
      counts = {
        total: Website.count,
        active: Website.where(status: 'active').count,
        processing: Website.where(status: 'processing').count,
        failed: Website.where(status: 'failed').count
      }
      cache_website_status_counts(counts)

      # Cache total chunks count
      Rails.cache.write('total_chunks_count', WebsiteChunk.count, expires_in: WEBSITE_STATUS_CACHE_EXPIRY)
    end

    private

    def generate_question_cache_key(question)
      # Create a consistent hash of the question for caching
      question_hash = Digest::SHA256.hexdigest(question.strip.downcase)
      "#{QUESTION_CACHE_KEY}:#{question_hash}"
    end

    def generate_embedding_cache_key(text)
      text_hash = Digest::SHA256.hexdigest(text.strip.downcase)
      "#{EMBEDDING_CACHE_KEY}:#{text_hash}"
    end

    def generate_similar_chunks_cache_key(question)
      question_hash = Digest::SHA256.hexdigest(question.strip.downcase)
      "#{SIMILAR_CHUNKS_CACHE_KEY}:#{question_hash}"
    end
  end
end
