require "test_helper"

class LocalTransactionPresenterTest < ActiveSupport::TestCase
  setup do
    LocalService.create(lgsl_code: 431, providing_tier: %w[county unitary])
  end

  def subject
    Formats::LocalTransactionPresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(
      :local_transaction_edition,
      state: "published",
      title: "Catch all rats",
      slug: "pest-control",
      panopticon_id: artefact.id,
      lgsl_code: 431,
      lgil_code: 8,
      introduction: "hello",
      more_information: "more info",
      need_to_know: "for your eyes only",
    )
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "local_transaction")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "local_transaction")
  end

  it_includes_last_edited_by_editor_id

  should "[:schema_name]" do
    assert_equal "local_transaction", result[:schema_name]
  end

  context "[:details]" do
    context "required details" do
      should "[:lgsl_code]" do
        expected = 431
        assert_equal expected, result[:details][:lgsl_code]
      end

      should "[:lgil_code]" do
        expected = 8
        assert_equal expected, result[:details][:lgil_code]
      end

      should "[:service_tiers]" do
        expected = %w[county unitary]
        assert_equal expected, result[:details][:service_tiers]
      end
    end

    context "optional details" do
      context "[:introduction]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "hello",
            },
          ]
          assert_equal expected, result[:details][:introduction]
        end

        should "not present the data if nil" do
          edition.introduction = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :introduction
        end
      end

      context "[:more_information]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "more info",
            },
          ]
          assert_equal expected, result[:details][:more_information]
        end

        should "not present the data if nil" do
          edition.more_information = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :more_information
        end
      end

      context "[:need_to_know]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "for your eyes only",
            },
          ]
          assert_equal expected, result[:details][:need_to_know]
        end

        should "not present the data if nil" do
          edition.need_to_know = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :need_to_know
        end
      end

      context "[:before_results]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "##before",
            },
          ]
          assert_equal expected, result[:details][:before_results]
        end

        should "not present the data if nil" do
          edition.before_results = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :before_results
        end
      end

      context "[:after_results]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "##after",
            },
          ]
          assert_equal expected, result[:details][:after_results]
        end

        should "not present the data if nil" do
          edition.after_results = nil
          edition.save!(validate: false)
          assert_not_includes result[:details].keys, :after_results
        end
      end
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

    should "[:routes]" do
      edition.slug = "foo"
      edition.save!(validate: false)
      expected = [
        { path: "/foo", type: "prefix" },
      ]
      assert_equal expected, result[:routes]
    end

    context "devolved administration availability" do
      should "not present any devolved administration availability values by default" do
        edition.save!(validate: false)
        assert_not result[:details].key?(:wales_availability)
        assert_not result[:details].key?(:scotland_availability)
        assert_not result[:details].key?(:northern_ireland_availability)
      end

      should "not present the data if local_authority_service was selected" do
        FactoryBot.create(:scotland_availability, authority_type: "local_authority_service", alternative_url: "", local_transaction_edition: edition.editionable)

        assert_not result[:details].key?(:scotland_availability)
      end

      should "present the type data if unavailable was selected" do
        edition.editionable.wales_availability.authority_type = "unavailable"

        edition.save!(validate: false)

        expected = { type: "unavailable" }
        assert_equal expected, result[:details][:wales_availability]
      end

      should "present the type and url data if devolved_administration_service was selected" do
        FactoryBot.create(:northern_ireland_availability, authority_type: "devolved_administration_service", alternative_url: "https://www.ni.gov/service", local_transaction_edition: edition.editionable)

        expected = { type: "devolved_administration_service", alternative_url: "https://www.ni.gov/service" }
        assert_equal expected, result[:details][:northern_ireland_availability]
      end
    end
  end
end
