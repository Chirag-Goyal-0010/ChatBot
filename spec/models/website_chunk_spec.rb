require 'rails_helper'

RSpec.describe WebsiteChunk, type: :model do
  describe 'associations' do
    it { should belong_to(:website) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    
    context 'on update' do
      let(:chunk) { create(:website_chunk) }
      
      it 'validates presence of embedding' do
        expect(chunk).to validate_presence_of(:embedding).on(:update)
      end
    end
  end

  describe '.similar_chunks' do
    let!(:website) { create(:website) }
    let!(:chunks) { create_list(:website_chunk, 3, :with_embedding, website: website) }

    context 'with valid question' do
      it 'returns chunks ordered by similarity' do
        allow(EmbeddingService).to receive(:new).and_return(double(embed: Array.new(1536, 0.5)))
        
        result = WebsiteChunk.similar_chunks('test question', limit: 2)
        expect(result.count).to eq(2)
      end
    end

    context 'with empty question' do
      it 'returns none' do
        result = WebsiteChunk.similar_chunks('', limit: 5)
        expect(result).to eq(WebsiteChunk.none)
      end
    end

    context 'with nil question' do
      it 'returns none' do
        result = WebsiteChunk.similar_chunks(nil, limit: 5)
        expect(result).to eq(WebsiteChunk.none)
      end
    end
  end

  describe '.similar_to' do
    let!(:chunks) { create_list(:website_chunk, 3, :with_embedding) }
    let(:valid_embedding) { Array.new(1536, 0.5) }
    let(:invalid_embedding) { [1, 2, 3] }

    it 'returns similar chunks for valid embedding' do
      result = WebsiteChunk.similar_to(valid_embedding, limit: 2)
      expect(result.count).to eq(2)
    end

    it 'returns none for invalid embedding' do
      result = WebsiteChunk.similar_to(invalid_embedding, limit: 5)
      expect(result).to eq(WebsiteChunk.none)
    end

    it 'returns none for non-array embedding' do
      result = WebsiteChunk.similar_to('not an array', limit: 5)
      expect(result).to eq(WebsiteChunk.none)
    end
  end

  describe '.test_vector_storage' do
    it 'creates a test chunk and returns metadata' do
      result = WebsiteChunk.test_vector_storage
      
      expect(result).to include(:id, :has_embedding, :embedding_length, :content)
      expect(result[:content]).to eq('This is a test chunk for vector storage verification.')
    end
  end
end
