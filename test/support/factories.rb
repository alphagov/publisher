require "factory_bot"
require "answer_edition"
require "artefact"
require "user"

FactoryBot.define do
  trait :scheduled_for_publishing do
    state { "scheduled_for_publishing" }
    publish_at { 1.day.from_now }
  end

  trait :published do
    state { "published" }
  end

  trait :ready do
    state { "ready" }
  end

  trait :fact_check do
    state { "fact_check" }
  end

  trait :fact_check_received do
    state { "fact_check_received" }
  end

  trait :in_review do
    state { "in_review" }
    review_requested_at { Time.zone.now }
  end

  trait :draft do
    state { "draft" }
  end

  trait :archived do
    state { "archived" }
  end

  trait :amends_needed do
    state { "amends_needed" }
  end

  trait :with_link_check_report do
    transient do
      batch_id { 1 }
      link_uris { [] }
    end

    link_check_reports do
      [FactoryBot.build(
        :link_check_report,
        :with_links,
        batch_id:,
        link_uris:,
      )]
    end
  end

  factory :user do
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.com" }
    organisation_content_id { PublishService::GDS_ORGANISATION_ID }

    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { %w[signin] }
    end

    trait :govuk_editor do
      permissions { %w[govuk_editor signin] }
    end

    trait :welsh_editor do
      permissions { %w[welsh_editor signin] }
    end

    trait :departmental_editor do
      permissions { %w[departmental_editor signin] }
    end

    trait :skip_review do
      permissions { %w[skip_review signin] }
    end
  end

  trait :homepage_editor do
    permissions { %w[homepage_editor signin] }
  end

  factory :disabled_user, parent: :user do
    disabled { true }
  end

  factory :downtime do
    message { "This service will be unavailable from 3pm to 6pm tomorrow" }
    tomorrow = Time.zone.tomorrow
    start_time { Time.zone.local(tomorrow.year, tomorrow.month, tomorrow.day, 15).time }
    end_time { Time.zone.local(tomorrow.year, tomorrow.month, tomorrow.day, 18).time }
    artefact_id { FactoryBot.create(:artefact).id }
  end

  factory :artefact do
    sequence(:name) { |n| "Artefact #{n}" }
    sequence(:slug) { |n| "slug-#{n}" }
    kind { Artefact::FORMATS.first }
    owning_app { "publisher" }
    content_id { SecureRandom.uuid }
    language { "en" }

    trait :with_published_edition do
      after(:create) do |object|
        create("#{object.kind}_edition".to_sym, panopticon_id: object.id, slug: object.slug, state: "published")
      end
    end

    trait :non_publisher do
      kind { "smart-answer" }
      owning_app { "smartanswers" }
    end

    trait :draft do
      state { "draft" }
    end

    trait :live do
      state { "live" }
    end

    trait :archived do
      state { "archived" }
    end

    factory :draft_artefact, traits: [:draft]
    factory :live_artefact, traits: [:live]
    factory :archived_artefact, traits: [:archived]

    factory :live_artefact_with_edition, traits: %i[live with_published_edition]

    factory :non_publisher_artefact, traits: [:non_publisher]
  end

  factory :edition do
    transient do
      body { "Some body text" }
    end

    editionable do
      build(:create_answer, body:)
    end

    sequence(:version_number)

    panopticon_id do
      a = create(:artefact, kind: kind_for_artefact)
      a.id
    end

    sequence(:slug) { |n| "slug-#{n}" }
    sequence(:title) { |n| "A key answer to your question #{n}" }

    after :build do |ed, evaluator|
      if !evaluator.version_number.nil?
        ed.version_number = evaluator.version_number
      elsif (previous = ed.series.order(version_number: "desc").first)
        ed.version_number = previous.version_number + 1
      end
    end

    trait :welsh do
      panopticon_id { create(:artefact, language: "cy", kind: kind_for_artefact).id }
    end

    trait :scheduled_for_publishing do
      state { "scheduled_for_publishing" }
      publish_at { 1.day.from_now }
    end

    trait :published do
      state { "published" }
    end

    trait :ready do
      state { "ready" }
    end

    trait :fact_check do
      transient do
        requester { FactoryBot.create(:user, :govuk_editor) }
        sent_out_at { Time.zone.now }
      end

      state { "fact_check" }
      actions { [FactoryBot.build(:action, request_type: Action::SEND_FACT_CHECK, customised_message: "Example customised message", requester:, created_at: sent_out_at)] }
    end

    trait :fact_check_received do
      transient do
        received_at { Time.zone.now }
      end

      state { "fact_check_received" }
      actions { [FactoryBot.build(:action, request_type: Action::RECEIVE_FACT_CHECK, created_at: received_at)] }
    end

    trait :in_review do
      transient do
        requester { FactoryBot.create(:user, :govuk_editor) }
      end

      state { "in_review" }
      actions { [FactoryBot.build(:action, request_type: Action::REQUEST_REVIEW, requester:)] }
      review_requested_at { Time.zone.now }
    end

    trait :draft do
      state { "draft" }
    end

    trait :with_body do
      body { "Some body text" }
    end
  end

  factory :answer_edition, class: "Edition" do
    title { "New Title" }
    transient do
      body { "some body" }
    end

    editionable do
      build(:create_answer, body:)
    end

    sequence(:version_number)

    trait :welsh do
      panopticon_id { create(:artefact, language: "cy", kind: kind_for_artefact).id }
    end

    panopticon_id do
      a = create(:artefact)
      a.id if a
    end
  end

  factory :create_answer, class: "AnswerEdition" do
  end

  factory :answer_edition_with_link_check_report, traits: [:with_link_check_report], parent: :answer_edition do
  end

  factory :help_page_edition, class: "Edition" do
    title { "New Title" }
    transient do
      body { "Some body text" }
    end

    editionable do
      build(:create_help_page, body:)
    end

    panopticon_id do
      a = create(:artefact)
      a.id
    end

    sequence(:slug) { |n| "help/slug-#{n}" }
    sequence(:version_number)
  end

  factory :create_help_page, class: "HelpPageEdition" do
  end

  factory :completed_transaction_edition, class: "Edition" do
    sequence(:slug) { |n| "help/slug-#{n}" }
    sequence(:version_number)

    title { "New Title" }
    transient do
      promotion_choice { "" }
      body { "Some body text" }
    end

    editionable do
      build(:create_completed_transaction, body:, promotion_choice:)
    end

    panopticon_id do
      a = create(:artefact)
      a.id
    end
  end

  factory :create_completed_transaction, class: "CompletedTransactionEdition" do
  end

  factory :guide_edition, class: "Edition" do
    title { "New Title" }
    transient do
      video_url { "some video url" }
    end

    editionable do
      video_url.eql?("some video url") ? build(:create_guide) : build(:create_guide, video_url:)
    end

    panopticon_id do
      a = create(:artefact, kind: "guide")
      a.id
    end

    state { "draft" }

    trait :welsh do
      panopticon_id { create(:artefact, language: "cy", kind: kind_for_artefact).id }
    end

    sequence(:version_number)
  end

  factory :create_guide, class: "GuideEdition" do
  end

  factory :popular_links, class: "Edition" do
    title { "Homepage Popular Links" }
    auth_bypass_id { SecureRandom.uuid }
    transient do
      link_items { [{ "url": "/url1", "title": "title1" }, { "url": "/url2", "title": "title2" }, { "url": "/url3", "title": "title3" }, { "url": "/url4", "title": "title4" }, { "url": "/url5", "title": "title5" }, { "url": "/url6", "title": "title6" }] }
    end
    editionable do
      build(:create_popular_links, link_items:)
    end

    panopticon_id do
      a = build(:artefact)
      a.id
    end
  end

  factory :create_popular_links, class: "PopularLinksEdition" do
  end

  factory :guide_edition_with_two_parts, parent: :guide_edition do
    after :build do |guide_edition|
      guide_edition.parts.build(
        title: "PART !",
        body: "This is some version text.",
        slug: "part-one",
        order: 1,
      )
      guide_edition.parts.build(
        title: "PART !!",
        body: "This is some more version text.",
        slug: "part-two",
        order: 2,
      )
    end
  end

  factory :guide_edition_and_parts_have_mongo_ids, parent: :guide_edition do
    after :build do |guide_edition|
      guide_edition.parts.build(
        title: "PART !",
        body: "This is some version text.",
        slug: "part-one",
        order: 1,
        mongo_id: "MongoIsNoMore1",
      )
      guide_edition.parts.build(
        title: "PART !!",
        body: "This is some more version text.",
        slug: "part-two",
        order: 2,
        mongo_id: "MongoIsNoMore2",
      )
    end
  end

  factory :guide_edition_with_two_govspeak_parts, parent: :guide_edition do
    after :create do |getp|
      getp.parts.build(
        title: "Some Part Title!",
        body: "This is some **version** text.",
        slug: "part-one",
      )
      getp.parts.build(
        title: "Another Part Title",
        body: "This is [link](http://example.net/) text.",
        slug: "part-two",
      )
    end
  end

  factory :scotland_availability, class: "ScotlandAvailability", parent: :devolved_administration_availability do
  end

  factory :wales_availability, class: "WalesAvailability", parent: :devolved_administration_availability do
  end

  factory :northern_ireland_availability, class: "NorthernIrelandAvailability", parent: :devolved_administration_availability do
  end

  factory :local_transaction_edition, class: "Edition" do
    title { "New Title" }
    transient do
      cta_text { "Find your local council" }
      introduction { "Test introduction" }
      more_information { "This is more information" }
      need_to_know { "This service is only available in England and Wales" }
      before_results { "##before" }
      after_results { "##after" }
      scotland_availability { build(:scotland_availability) }
      wales_availability { build(:wales_availability) }
      northern_ireland_availability { build(:northern_ireland_availability) }
    end

    editionable do
      build(:create_local_transaction, lgil_code:, lgsl_code:, introduction:, cta_text:, more_information:, need_to_know:, before_results:, after_results:, scotland_availability:, wales_availability:, northern_ireland_availability:)
    end

    panopticon_id do
      a = create(:artefact)
      a.id if a
    end

    lgsl_code do
      local_service = create(:local_service)
      local_service.lgsl_code
    end
    lgil_code { 1 }

    sequence(:version_number)
  end

  factory :create_local_transaction, class: "LocalTransactionEdition" do
  end

  factory :devolved_administration_availability, class: "DevolvedAdministrationAvailability" do
  end

  factory :transaction_edition, class: "Edition" do
    title { "New Title" }
    transient do
      introduction { "Test introduction" }
      more_information { "This is more information" }
      need_to_know { "This service is only available in England and Wales" }
      link { "http://continue.com" }
      will_continue_on { "To be continued..." }
      alternate_methods { "Method A or Method B" }
    end

    editionable do
      build(:create_transaction, introduction:, more_information:, need_to_know:, link:, will_continue_on:, alternate_methods:)
    end

    panopticon_id do
      a = create(:artefact, kind: "transaction")
      a.id if a
    end

    sequence(:version_number)
  end

  factory :create_transaction, class: "TransactionEdition" do
  end

  factory :local_service do |ls|
    ls.sequence(:lgsl_code)
    providing_tier { %w[district unitary county] }
  end

  factory :local_authority do
    name { "Some Council" }
    sequence(:snac) { |n| sprintf "%02dAA", n }
    sequence(:local_directgov_id)
    tier { "county" }
  end

  factory :place_edition, class: "Edition" do
    title { "Far far away" }
    transient do
      introduction { "Test introduction" }
      more_information { "More information" }
      need_to_know { "This service is only available in England and Wales" }
      place_type { "Location location location" }
    end

    editionable do
      build(:create_place, introduction:, more_information:, need_to_know:, place_type:)
    end

    panopticon_id do
      a = create(:artefact, kind: "place")
      a.id if a
    end

    sequence(:version_number)
  end

  factory :create_place, class: "PlaceEdition" do
  end

  factory :curated_list do
    sequence(:slug) { |n| "slug-#{n}" }
  end

  factory :rendered_manual do
    sequence(:slug) { |n| "test-rendered-manual-#{n}" }
    sequence(:title) { |n| "Test Rendered Manual #{n}" }
    summary { "My summary" }
  end

  factory :simple_smart_answer_edition, class: "Edition" do
    title { "Simple smart answer" }
    transient do
      body { "Introduction to the smart answer" }
    end

    editionable do
      build(:create_simple_smart_answer, body:)
    end

    panopticon_id do
      a = create(:artefact, kind: "simple_smart_answer")
      a.id if a
    end

    trait :welsh do
      panopticon_id { create(:artefact, language: "cy", kind: kind_for_artefact).id }
    end

    sequence(:version_number)
  end

  factory :create_simple_smart_answer, class: "SimpleSmartAnswerEdition" do
  end

  factory :node, class: "SimpleSmartAnswerEdition::Node" do
  end

  factory :option, class: "SimpleSmartAnswerEdition::Node::Option" do
  end

  factory :link do
    uri { "https://www.gov.uk" }
    status { "ok" }
    checked_at { Time.zone.parse("2017-12-01").iso8601 }
    check_warnings { ["example check warnings"] }
    check_errors { ["example check errors"] }
    problem_summary { "example problem" }
    suggested_fix { "example fix" }
  end

  factory :host_content_update_event, class: "HostContentUpdateEvent" do
    author { build(:host_content_update_event_author) }
    created_at { Time.zone.now }
    content_id { SecureRandom.uuid }
    content_title { "Something" }
    document_type { "document_type" }

    initialize_with do
      new(
        author:,
        created_at:,
        content_id:,
        content_title:,
        document_type:,
      )
    end
  end

  factory :host_content_update_event_author, class: "HostContentUpdateEvent::Author" do
    name { "Someone" }
    email { "foo@example.com" }

    initialize_with do
      new(
        name:,
        email:,
      )
    end
  end

  factory :link_check_report do
    batch_id { 1 }
    status { "in_progress" }
    edition { FactoryBot.create(:edition) }
    links { [FactoryBot.build(:link)] }

    trait :completed do
      status { "completed" }
      completed_at { Time.zone.now.iso8601 }
    end

    trait :with_links do
      transient do
        link_uris { [] }
        link_status { "pending" }
      end

      links do
        link_uris.map { |uri| FactoryBot.build(:link, uri:, status: link_status) }
      end
    end
  end

  factory :action do
    request_type { Action::IMPORTANT_NOTE }
    edition
    requester { FactoryBot.create(:user) }
    comment { "Default comment" }
  end
end
