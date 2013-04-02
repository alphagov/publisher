require 'test_helper'
require 'edition_progressor'

class EditionProgressorTest < ActiveSupport::TestCase

  setup do
    @laura = FactoryGirl.create(:user)
    @statsd = stub_everything
    @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    stub_register_published_content
  end

  test "should be able to progress an item" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "user@example.com",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura, @statsd)
    assert command.progress(activity)

    @guide.reload
    assert_equal 'fact_check', @guide.state
  end

  test "should not progress to fact check if the email addresses were blank" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura, @statsd)
    refute command.progress(activity)
  end

  test "should not progress to fact check if the email addresses were invalid" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "nouseratexample.com",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura, @statsd)
    refute command.progress(activity)
  end
end