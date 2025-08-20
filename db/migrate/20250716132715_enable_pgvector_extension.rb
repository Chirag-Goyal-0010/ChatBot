class EnablePgvectorExtension < ActiveRecord::Migration[8.0]
  def change
    # Only enable vector extension if it's available
    if extension_available?("vector")
      enable_extension "vector"
    else
      Rails.logger.warn "pgvector extension not available - skipping vector extension enable"
    end
  end
  
  private
  
  def extension_available?(name)
    connection.execute("SELECT 1 FROM pg_available_extensions WHERE name = '#{name}'").any?
  rescue => e
    Rails.logger.warn "Could not check for extension #{name}: #{e.message}"
    false
  end
end
