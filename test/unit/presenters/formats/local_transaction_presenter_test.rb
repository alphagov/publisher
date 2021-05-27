require "test_helper"

class LocalTransactionPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  setup do
    LocalService.create(lgsl_code: 431, providing_tier: %w[county unitary])
  end

  def subject
    Formats::LocalTransactionPresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(
      :local_transaction_edition,
      :published,
      title: "Catch all rats",
      slug: "pest-control",
      panopticon_id: artefact.id,
      lgsl_code: 431,
      lgil_code: 8,
      introduction: "hello",
      more_information: "more info",
      need_to_know: "for your eyes only",
      scotland_availability: FactoryBot.build(
        :devolved_administration_availability,
      ),
      wales_availability: FactoryBot.build(
        :devolved_administration_availability,
      ),
      northern_ireland_availability: FactoryBot.build(
        :devolved_administration_availability,
      ),
    )
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "local_transaction")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, "local_transaction")
  end

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

    context "[:scotland_availability]" do
      should "not present the data if local_authority_service was selected" do
        edition.scotland_availability = { type: "local_authority_service", alternative_url: "" }
        edition.save!(validate: false)

        expected = nil
        assert_equal expected, result[:details][:scotland_availability]
      end

      should "present the type data if unavailable was selected" do
        edition.scotland_availability = FactoryBot.build(
          :devolved_administration_availability,
          type: "unavailable",
        )
        edition.save!(validate: false)

        expected = { type: "unavailable" }
        assert_equal expected, result[:details][:scotland_availability]
      end

      should "present the type and url data if devolved_administration_service was selected" do
        edition.scotland_availability = FactoryBot.build(
          :devolved_administration_availability,
          type: "devolved_administration_service",
          alternative_url: "https://www.scot.gov/service",
        )
        edition.save!(validate: false)

        expected = { type: "devolved_administration_service", alternative_url: "https://www.scot.gov/service" }
        assert_equal expected, result[:details][:scotland_availability]
      end
    end
  end
end
