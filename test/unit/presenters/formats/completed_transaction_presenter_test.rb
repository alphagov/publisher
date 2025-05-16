require "test_helper"

class CompletedTransactionPresenterTest < ActiveSupport::TestCase
  setup do
    @edition = FactoryBot.create(
      :completed_transaction_edition,
      :published,
      title: "Whacked all moles",
      slug: "done/good",
      panopticon_id: artefact.id,
    )
  end

  def subject
    Formats::CompletedTransactionPresenter.new(@edition)
  end

  attr_reader :edition

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "completed_transaction", slug: "done/artefact")
  end

  def result
    subject.render_for_publishing_api
  end

  it_includes_last_edited_by_editor_id

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "completed_transaction")
  end

  should "[:schema_name]" do
    assert_equal "completed_transaction", result[:schema_name]
  end

  context "[:details]" do
    should "[:promotion]" do
      @edition.presentation_toggles["promotion_choice"] = {
        "choice" => "mot_reminder",
        "url" => "http://www.foo.com",
      }

      expected = {
        category: "mot_reminder",
        url: "http://www.foo.com",
      }

      assert_equal expected, result[:details][:promotion]
    end

    should "opt in and opt out [:promotion]" do
      @edition.presentation_toggles["promotion_choice"] = {
        "choice" => "organ_donor",
        "url" => "http://www.foo.com",
        "opt_in_url" => "http://www.bar.com",
        "opt_out_url" => "http://www.baz.com",
      }

      expected = {
        category: "organ_donor",
        url: "http://www.foo.com",
        opt_in_url: "http://www.bar.com",
        opt_out_url: "http://www.baz.com",
      }

      assert_equal expected, result[:details][:promotion]
    end

    should "no [:promotion]" do
      @edition.presentation_toggles["promotion_choice"] = {
        "choice" => "none",
        "url" => "",
      }

      assert_nil result[:details][:promotion]
    end

    should "[:external_related_links]" do
      link = { "url" => "https://www.foo.com", "title" => "foo" }
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

    should "[:rendering_app]" do
      assert_equal "feedback", result[:rendering_app]
    end
  end

  should "[:routes]" do
    @edition.update!(slug: "foo")
    expected = [
      { path: "/foo", type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end
end
