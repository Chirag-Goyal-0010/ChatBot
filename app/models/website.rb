class Website < ApplicationRecord
  has_many :website_chunks, dependent: :destroy
  # validates :url, url: true  # Temporarily commented out for testing
end
