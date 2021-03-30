FactoryBot.define do
  factory :teacher, class: Teacher do
    association :room, factory: :room
    sequence(:id)   { |n| n }
    sequence(:name) { |n| "講師#{n}" }
    email           { 'teacher@example.com' }
    is_deleted      { false }
  end
end
