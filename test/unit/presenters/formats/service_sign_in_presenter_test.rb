require 'test_helper'

class ServiceSignInTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::ServiceSignInPresenter.new(@content)
  end

  def file_name
    "example.yaml"
  end

  def load_content_from_file(file_name)
    @content ||= YAML.load_file(Rails.root.join("lib", "service_sign_in", file_name)).deep_symbolize_keys
  end

  def setup
    load_content_from_file(file_name)
    @artefact ||= FactoryGirl.create(:artefact, kind: "transaction")
    @parent ||= FactoryGirl.create(
      :transaction_edition,
      panopticon_id: @artefact.id,
      slug: parent_slug
    )
  end

  def parent_slug
    "log-in-file-self-assessment-tax-return"
  end

  def base_path
    "/#{parent_slug}/sign-in"
  end

  def result
    subject.render_for_publishing_api
  end

  context "#content_id" do
    should "create a new content id if we are creating a new content item" do
      SecureRandom.stub :uuid, "random-uuid-string" do
        publishing_api_has_lookups(base_path => nil)
        assert_equal "random-uuid-string", subject.content_id
      end
    end

    should "use existing content_id if content_item already exists in content-store" do
      content_id = "random-content-id"
      publishing_api_has_lookups(base_path => content_id)

      assert_equal content_id, subject.content_id
    end
  end

  should "[:schema_name]" do
    assert_equal 'service_sign_in', result[:schema_name]
  end

  should "[:rendering_app]" do
    assert_equal 'government-frontend', result[:rendering_app]
  end

  should "[:publishing_app]" do
    assert_equal 'publisher', result[:publishing_app]
  end

  should "[:document_type]" do
    assert_equal 'service_sign_in', result[:document_type]
  end

  should "[:locale]" do
    assert_equal @content[:locale], result[:locale]
  end

  should "[:update_type]" do
    assert_equal @content[:update_type], result[:update_type]
  end

  should "[:change_note]" do
    assert_equal @content[:change_note], result[:change_note]
  end

  should "[:base_path]" do
    assert_equal base_path, result[:base_path]
  end

  should "[:routes]" do
    expected = [
      { path: base_path, type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end

  should "[:title]" do
    assert_equal @parent.title, result[:title]
  end

  should "[:description]" do
    assert_equal @parent.overview, result[:description]
  end

  context "[:public_updated_at]" do
    should "return current timestamp when update_type is 'major'" do
      Timecop.freeze do
        assert_equal DateTime.now.rfc3339, result[:public_updated_at]
      end
    end

    should "not be present in the payload when update_type is not 'major'" do
      @content[:update_type] = "minor"
      Timecop.freeze do
        refute_includes result, public_updated_at: DateTime.now.rfc3339
      end
    end
  end

  should "#links" do
    expected = {
      parent: [@parent.content_id]
    }

    assert_equal expected, subject.links
  end

  context "[:details]" do
    context "[:choose_sign_in]" do
      should "[:title]" do
        assert_equal @content[:choose_sign_in][:title],
          result[:details][:choose_sign_in][:title]
      end

      should "[:slug]" do
        assert_equal @content[:choose_sign_in][:slug],
          result[:details][:choose_sign_in][:slug]
      end

      should "[:description]" do
        expected = [
          {
            content_type: "text/govspeak",
            content: @content[:choose_sign_in][:description]
          }
        ]
        assert_equal expected, result[:details][:choose_sign_in][:description]
      end
    end
  end
end
