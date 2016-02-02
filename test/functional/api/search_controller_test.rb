require 'test_helper'

class Api::SearchControllerTest < ActionController::TestCase
  def setup
    login_as_stub_user

    @relevant_editions = [
      # Published with correct primary tag
      FactoryGirl.create(:edition, state: 'published', primary_topic: 'oil-and-gas/licensing'),
      # Published with correct secondary tag
      FactoryGirl.create(:edition, state: 'published', additional_topics: ['oil-and-gas/licensing'])
    ]

    @irrelevant_editions = [
      # Correct tag, but draft
      FactoryGirl.create(:edition, state: 'draft', primary_topic: 'oil-and-gas/licensing'),
      # Correct tag, but archived
      FactoryGirl.create(:edition, state: 'archived', primary_topic: 'oil-and-gas/licensing'),
      # Published, but incorrect tag
      FactoryGirl.create(:edition, state: 'published', additional_topics: ['environmental-management/boating']),
      # Published, but no tag
      FactoryGirl.create(:edition, state: 'published')
    ]

    PublishingAPIPublisher.stubs(:perform_async)
  end

  test "#reindex_topic_editions resubmits to panopticon all published editions tagged to the topic" do
    @relevant_editions.each do |edition|
      registerable = mock("registerable_edition")
      RegisterableEdition.stubs(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable).once
    end

    @irrelevant_editions.each do |edition|
      registerable = mock("registerable_edition")
      RegisterableEdition.stubs(:new).with(edition).returns(registerable)
      GdsApi::Panopticon::Registerer.any_instance.expects(:register).with(registerable).never
    end

    post :reindex_topic_editions, {slug: 'oil-and-gas/licensing'},
      {'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json'}

    assert_response 202
  end
end
