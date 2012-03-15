FactoryGirl.define do
  factory :user do
    uid   { Faker::Name.name.downcase.gsub(/[^a-z]+/, "_") }
    name  { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :guide_edition do |ge|
    ge.sequence(:panopticon_id) { |n| n }
    title  { Faker::Company.bs }
    ge.sequence(:slug) { |ns| "slug-#{ns}"}
  end

  factory :guide_edition_with_two_parts, :parent => :guide_edition do
    title 'a title'
    after_build do |getp|
      getp.parts.build(title: 'PART !', body: "This is some version text.", slug: 'part-one')
      getp.parts.build(title: 'PART !!', body: "This is some more version text.", slug: 'part-two')
    end
  end
end
