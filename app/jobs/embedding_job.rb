class EmbeddingJob < ApplicationJob
  queue_as :default
  
  # Job retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  retry_on OpenAI::Error, wait: 10.seconds, attempts: 5

  def perform(chunk_id)
    chunk = WebsiteChunk.find(chunk_id)
    
    begin
      service = EmbeddingService.new
      embedding_array = service.embed(chunk.content)
      
      if embedding_array && embedding_array.is_a?(Array) && embedding_array.length == 1536
        chunk.update!(embedding: embedding_array)
        Rails.logger.info("Successfully generated embedding for chunk #{chunk.id}")
      else
        Rails.logger.error("Failed to generate valid embedding for chunk #{chunk.id}")
        raise "Invalid embedding format"
      end
    rescue => e
      Rails.logger.error("Embedding generation failed for chunk #{chunk.id} (attempt #{executions}): #{e.message}")
      
      # Mark chunk as failed if this is the final attempt
      if executions >= self.class.retry_attempts
        chunk.update_column(:embedding, nil)
        Rails.logger.error("Final attempt failed for chunk #{chunk.id}, marked as failed")
      end
      
      raise e
    end
  end
end