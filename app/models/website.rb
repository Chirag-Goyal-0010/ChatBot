class Website < ApplicationRecord
  has_many :website_chunks, dependent: :destroy, counter_cache: :chunks_count
  validates :url, url: true, presence: true
  validates :status, inclusion: { in: %w[active inactive processing failed] }, allow_nil: true
  
  before_validation :normalize_url
  
  scope :active, -> { where(status: 'active') }
  scope :failed, -> { where(status: 'failed') }
  scope :processing, -> { where(status: 'processing') }
  
  # Job monitoring methods
  def mark_scraping_complete!
    update!(
      status: 'active',
      scraped_at: Time.current,
      error_message: nil
    )
  end
  
  def mark_scraping_failed!(error_message)
    update!(
      status: 'failed',
      error_message: error_message,
      scraped_at: Time.current
    )
  end
  
  def scraping_duration
    return nil unless scraped_at && created_at
    scraped_at - created_at
  end
  
  def has_content?
    chunks_count > 0
  end
  
  private
  
  def normalize_url
    return unless url.present?
    self.url = url.strip
    # Add protocol if missing
    self.url = "https://#{url}" unless url.match?(/\Ahttps?:\/\//)
  end
end
