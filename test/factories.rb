FactoryGirl.define do
  factory :user do
    uid   { Faker::Name.name.downcase.gsub(/[^a-z]+/, "_") }
    name  { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :guide do
    name  { Faker::Company.bs }
    slug  { Faker::Company.bs.downcase.gsub(/[^a-z]+/, "-") }
  end
end
