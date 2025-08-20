require 'rails_helper'

RSpec.describe EmbeddingService, type: :service do
  let(:service) { described_class.new }
  let(:mock_client) { double('OpenAI::Client') }
  let(:sample_embedding) { Array.new(1536, 0.5) }
  let(:mock_response) { { 'data' => [{ 'embedding' => sample_embedding }] } }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
    allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
  end

  describe '#initialize' do
    it 'creates a client with the API key' do
      expect(OpenAI::Client).to receive(:new).with(access_token: 'test-api-key')
      described_class.new
    end

    it 'raises error when API key is missing' do
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      expect { described_class.new }.to raise_error(/OPENAI_API_KEY environment variable is not set/)
    end
  end

  describe '#embed', :vcr do
    it 'returns embedding for valid text' do
      allow(mock_client).to receive(:embeddings).and_return(mock_response)
      
      result = service.embed('test text')
      expect(result).to eq(sample_embedding)
      expect(result.length).to eq(1536)
    end

    it 'raises error for empty text' do
      expect { service.embed('') }.to raise_error(/Input must be a non-empty string/)
    end

    it 'raises error for nil text' do
      expect { service.embed(nil) }.to raise_error(/Input must be a non-empty string/)
    end

    it 'handles OpenAI API errors' do
      allow(mock_client).to receive(:embeddings).and_raise(StandardError.new('API Error'))
      
      expect { service.embed('test') }.to raise_error(/Failed to generate embedding/)
    end
  end

  describe '#insert_embedding_for_chunk' do
    let(:chunk) { create(:website_chunk) }

    it 'successfully inserts embedding for valid chunk' do
      allow(service).to receive(:embed).and_return(sample_embedding)
      
      result = service.insert_embedding_for_chunk(chunk)
      expect(result).to be true
      expect(chunk.reload.embedding).to be_present
    end

    it 'returns false for invalid chunk' do
      result = service.insert_embedding_for_chunk('not a chunk')
      expect(result).to be false
    end

    it 'handles embedding generation errors' do
      allow(service).to receive(:embed).and_raise(StandardError.new('Embedding failed'))
      
      result = service.insert_embedding_for_chunk(chunk)
      expect(result).to be false
    end
  end

  describe '.find_similar_chunks' do
    let!(:chunks) { create_list(:website_chunk, 3, :with_embedding) }

    it 'returns similar chunks for valid question' do
      allow_any_instance_of(described_class).to receive(:embed).and_return(sample_embedding)
      allow(WebsiteChunk).to receive(:similar_to).and_return(chunks.limit(2))
      
      result = described_class.find_similar_chunks('test question', limit: 2)
      expect(result.count).to eq(2)
    end

    it 'returns nil when no chunks found' do
      allow_any_instance_of(described_class).to receive(:embed).and_return(sample_embedding)
      allow(WebsiteChunk).to receive(:similar_to).and_return(WebsiteChunk.none)
      
      result = described_class.find_similar_chunks('test question')
      expect(result).to be_nil
    end
  end

  describe '.test_service' do
    it 'returns success result for working service' do
      allow_any_instance_of(described_class).to receive(:embed).and_return(sample_embedding)
      
      result = described_class.test_service
      expect(result[:success]).to be true
      expect(result[:dimensions_match]).to be true
    end

    it 'returns failure result for broken service' do
      allow_any_instance_of(described_class).to receive(:embed).and_raise(StandardError.new('Service failed'))
      
      result = described_class.test_service
      expect(result[:success]).to be false
      expect(result[:error]).to be_present
    end
  end
end
