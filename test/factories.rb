FactoryGirl.define do
  factory :user do
    uid   { Faker::Name.name.downcase.gsub(/[^a-z]+/, "_") }
    name  { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :edition, :class => AnswerEdition do
    sequence(:panopticon_id)
    sequence(:slug) { |n| "slug-#{n}" }

    title { Faker::Name.name }
    section 'test:subsection test'

    association :assigned_to, :factory => :user
  end
  factory :answer_edition, :parent => :edition do
  end

  factory :guide_edition do |ge|
    ge.sequence(:panopticon_id) { |n| n }
    ge.sequence(:title)  { |n| "Test guide #{n}" }
    ge.sequence(:slug) { |ns| "slug-#{ns}"}
    section { 'test:subsection test' }
  end

  factory :programme_edition do |edition|
    edition.sequence(:panopticon_id) { |n| n }
    edition.sequence(:title)  { |n| "Test programme #{n}" }
    edition.sequence(:slug) { |ns| "slug-#{ns}"}
    section { 'test:subsection test' }
  end

  factory :guide_edition_with_two_parts, :parent => :guide_edition do
    title 'a title'
    after_build do |getp|
      getp.parts.build(title: 'PART !', body: "This is some version text.", slug: 'part-one')
      getp.parts.build(title: 'PART !!', body: "This is some more version text.", slug: 'part-two')
    end
  end

  factory :local_transaction_edition do |lte|
    lte.sequence(:panopticon_id) { |n| n }
    title  { 'Test title' }
    version_number 1
    lte.sequence(:slug) { |ns| "slug-#{ns}"}
    lte.sequence(:lgsl_code) { |nlgsl| nlgsl }
    introduction { 'Test introduction' }
    more_information { 'This is more information' }
  end

  factory :local_service do |ls|
    ls.sequence(:lgsl_code) { |nlgsl| nlgsl }
    providing_tier { %w{district unitary county} }
  end

  factory :local_authority do
    name "Some Council"
    sequence(:snac) {|n| "AA0#{n}" }
    sequence(:local_directgov_id)
    tier "county"
  end

  factory :local_authority_with_contact, :parent => :local_authority do
    contact_address ["line one", "line two", "line three"]
    contact_url "http://www.magic.com/contact"
    contact_phone '0206778654'
    contact_email 'contact@local.authority.gov.uk'
  end

  factory :local_interaction do
    association :local_authority
    url "http://some.council.gov/do.html"
    sequence(:lgsl_code) {|n| 120 + n }
    lgil_code 0
  end

end
