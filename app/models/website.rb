class Website < ApplicationRecord
  has_many :website_chunks, dependent: :destroy
  validates :url, url: true
end
