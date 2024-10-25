require "test_helper"

class LicencePresenterTest < ActiveSupport::TestCase
  def subject
    Formats::LicencePresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(
      :licence_edition,
      :published,
      title: "Licence to catch all rats",
      slug: "pest-control-licence",
      panopticon_id: artefact.id,
      licence_identifier: "123-2-1",
      will_continue_on: "Royal Rat Catching Institute",
      continuation_link: "https://www.royal-rats-institute.gov.uk",
      licence_short_description: "Gotta catch them all",
      licence_overview: "Yes you really do need to catch them all",
    )
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "licence")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "licence")
  end

  it_includes_last_edited_by_editor_id

  should "[:schema_name]" do
    assert_equal "licence", result[:schema_name]
  end

  context "[:details]" do
    context "required details" do
      should "[:licence_identifier]" do
        expected = "123-2-1"
        assert_equal expected, result[:details][:licence_identifier]
      end
    end

    context "optional details" do
      context "[:will_continue_on]" do
        should "present the data" do
          expected = "Royal Rat Catching Institute"
          assert_equal expected, result[:details][:will_continue_on]
        end

        should "not present the data if nil" do
          edition.will_continue_on = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :will_continue_on
        end
      end

      context "[:continuation_link]" do
        should "present the data" do
          expected = "https://www.royal-rats-institute.gov.uk"
          assert_equal expected, result[:details][:continuation_link]
        end

        should "not present the data if nil" do
          edition.continuation_link = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :continuation_link
        end
      end

      context "[:licence_short_description]" do
        should "present the data" do
          expected = "Gotta catch them all"
          assert_equal expected, result[:details][:licence_short_description]
        end

        should "not present the data if nil" do
          edition.licence_short_description = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :licence_short_description
        end
      end

      context "[:licence_overview]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "Yes you really do need to catch them all",
            },
          ]
          assert_equal expected, result[:details][:licence_overview]
        end

        should "not present the data if nil" do
          edition.licence_overview = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :licence_overview
        end
      end
    end

    should "[:external_related_links]" do
      link = { "url" => "www.foo.com", "title" => "foo" }
      artefact.external_links = [link]
      artefact.save!(validate: false)
      expected = [
        {
          url: link["url"],
          title: link["title"],
        },
      ]

      assert_equal expected, result[:details][:external_related_links]
    end

    should "[:routes]" do
      edition.slug = "foo"
      edition.save!(validate: false)
      expected = [
        { path: "/foo", type: "prefix" },
      ]
      assert_equal expected, result[:routes]
    end
  end
end
