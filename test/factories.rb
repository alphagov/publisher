FactoryGirl.define do
  factory :user do
    uid   { Faker::Name.name.downcase.gsub(/[^a-z]+/, "_") }
    name  { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :guide_edition do |ge|
  	ge.sequence(:panopticon_id) { |n| n }
    title  { Faker::Company.bs }
    slug  { Faker::Company.bs.downcase.gsub(/[^a-z]+/, "-") }
  end
end
