FactoryBot.define do
  factory :website do
    url { Faker::Internet.url }
    status { 'active' }

    trait :processing do
      status { 'processing' }
    end

    trait :failed do
      status { 'failed' }
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :with_chunks do
      after(:create) do |website|
        create_list(:website_chunk, 3, website: website)
      end
    end
  end
end
