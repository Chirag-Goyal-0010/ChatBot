FactoryBot.define do
  factory :website_chunk do
    association :website
    content { Faker::Lorem.paragraph(sentence_count: 5) }
    section { Faker::Lorem.words(number: 2).join(' ').titleize }
    position { rand(1..100) }
    embedding { nil }

    trait :with_embedding do
      embedding { Array.new(1536) { rand(-1.0..1.0) } }
    end

    trait :short_content do
      content { Faker::Lorem.sentence }
    end

    trait :long_content do
      content { Faker::Lorem.paragraph(sentence_count: 20) }
    end
  end
end
