class AddErrorTrackingToWebsites < ActiveRecord::Migration[8.0]
  def change
    add_column :websites, :error_message, :text
    add_column :websites, :scraped_at, :datetime
    add_column :websites, :chunks_count, :integer, default: 0
    
    add_index :websites, :scraped_at
    add_index :websites, :chunks_count
  end
end
