require "test_helper"

class TransactionPresenterTest < ActiveSupport::TestCase
  def subject
    Formats::TransactionPresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(:transaction_edition, panopticon_id: artefact.id)
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "transaction")
  end

  def create_downtime(message, start_time: Time.zone.yesterday.at_midnight)
    Downtime.create(
      artefact_id: artefact.id,
      start_time:,
      end_time: Time.zone.tomorrow.at_midnight,
      message:,
    )
  end

  def result
    subject.render_for_publishing_api
  end

  it_includes_last_edited_by_editor_id

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "transaction")
  end

  should "[:schema_name]" do
    assert_equal "transaction", result[:schema_name]
  end

  context "[:details]" do
    should "[:variants]" do
      expected = []

      assert_equal expected, result[:details][:variants]
    end

    should "[:introductory_paragraph]" do
      edition.update!(introduction: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:introductory_paragraph]
    end

    should "[:more_information]" do
      edition.update!(more_information: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:more_information]
    end

    should "[:other_ways_to_apply]" do
      edition.update!(alternate_methods: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:other_ways_to_apply]
    end

    should "[:what_you_need_to_know]" do
      edition.update!(need_to_know: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:what_you_need_to_know]
    end

    should "[:external_related_links]" do
      link = { "url" => "http://www.foo.com", "title" => "foo" }
      artefact.external_links = [ArtefactExternalLink.build(link)]
      artefact.save!
      expected = [
        {
          url: link["url"],
          title: link["title"],
        },
      ]

      assert_equal expected, result[:details][:external_related_links]
    end

    should "[:will_continue_on]" do
      edition.update!(will_continue_on: "foo")
      assert_equal "foo", result[:details][:will_continue_on]
    end

    should "[:transaction_start_link]" do
      edition.update!(link: "foo")
      assert_equal "foo", result[:details][:transaction_start_link]
    end

    should "[:start_button_text]" do
      edition.update!(start_button_text: "Sign in")
      assert_equal "Sign in", result[:details][:start_button_text]
    end

    context "[:downtime_message]" do
      context "when there is a downtime association" do
        should "show if we're in the publicize window" do
          message = "this transaction is unavailable tomorrow"
          create_downtime(message)
          assert message, result[:details][:downtime_message]
        end

        should "not render downtime if we're outside the publicize window" do
          create_downtime("foo", start_time: Time.zone.tomorrow.at_midday)
          assert_nil result[:details][:downtime_message]
        end
      end

      context "when there's no downtime scheduled" do
        should "not render downtime" do
          assert_nil result[:details][:downtime_message]
        end
      end
    end
  end

  should "[:routes]" do
    edition.update!(slug: "foo")
    expected = [
      { path: "/foo", type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end
end
