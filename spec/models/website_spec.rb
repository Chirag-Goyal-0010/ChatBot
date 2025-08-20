require 'rails_helper'

RSpec.describe Website, type: :model do
  describe 'associations' do
    it { should have_many(:website_chunks).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:url) }
    it { should validate_inclusion_of(:status).in_array(%w[active inactive processing failed]).allow_nil }

    describe 'url validation' do
      it 'accepts valid URLs' do
        website = build(:website, url: 'https://example.com')
        expect(website).to be_valid
      end

      it 'rejects invalid URLs' do
        website = build(:website, url: 'not-a-url')
        expect(website).not_to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#normalize_url' do
      it 'strips whitespace from URL' do
        website = create(:website, url: '  https://example.com  ')
        expect(website.url).to eq('https://example.com')
      end

      it 'adds https protocol if missing' do
        website = create(:website, url: 'example.com')
        expect(website.url).to eq('https://example.com')
      end

      it 'does not modify URLs that already have protocol' do
        website = create(:website, url: 'http://example.com')
        expect(website.url).to eq('http://example.com')
      end
    end
  end

  describe 'status management' do
    let(:website) { create(:website) }

    it 'can be set to processing' do
      website.update!(status: 'processing')
      expect(website.status).to eq('processing')
    end

    it 'can be set to failed' do
      website.update!(status: 'failed')
      expect(website.status).to eq('failed')
    end

    it 'can be set to inactive' do
      website.update!(status: 'inactive')
      expect(website.status).to eq('inactive')
    end
  end
end
