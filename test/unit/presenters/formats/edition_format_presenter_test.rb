require "test_helper"

class EditionFormatPresenterTest < ActiveSupport::TestCase
  def subject
    Formats::EditionFormatPresenter.new(edition)
  end

  def edition
    @edition ||= stub(artefact:, in_beta: false)
  end

  def artefact
    @artefact ||= stub
  end

  def result
    subject.render_for_publishing_api
  end

  context "#render_for_publishing_api" do
    setup do
      edition.stubs :title
      edition.stubs :slug
      edition.stubs :overview
      edition.stubs :public_updated_at
      edition.stubs updated_at: Time.zone.now
      edition.stubs :major_change
      edition.stubs :version_number
      edition.stubs :latest_change_note
      edition.stubs :auth_bypass_id
      edition.stubs :exact_route?

      artefact.stubs :language
    end

    should "[:title]" do
      edition.expects(:title).returns("foo")
      assert_equal "foo", result[:title]
    end

    should "[:base_path]" do
      edition.expects(:slug).returns("foo")
      assert_equal "/foo", result[:base_path]
    end

    context "[:description]" do
      should "return edition.overview if present" do
        edition.expects(:overview).returns("foo")
        assert_equal "foo", result[:description]
      end

      should "return '' if overview is nil" do
        assert_equal "", result[:description]
      end
    end

    should "[:schema_name]" do
      assert_equal "override me", result[:schema_name]
    end

    should "[:document_type]" do
      assert_equal "override me", result[:document_type]
    end

    context "when in beta" do
      should "include phase" do
        edition.expects(:in_beta).returns(true)
        assert_equal "beta", result[:phase]
      end
    end

    context "when not in beta" do
      should "not include phase" do
        edition.expects(:in_beta).returns(false)
        assert_not_includes result.keys, :phase
      end
    end

    context "[:public_updated_at]" do
      should "return edition.public_updated_at if not nil" do
        now = Time.zone.now
        edition.expects(:public_updated_at).returns(now)
        assert_equal now.rfc3339(3), result[:public_updated_at]
      end

      should "return edition.updated_at otherwise" do
        edition.stubs(:public_updated_at).returns(nil)
        now = Time.zone.now
        edition.expects(:updated_at).returns(now)
        assert_equal now.rfc3339(3), result[:public_updated_at]
      end
    end

    should "[:publishing_app]" do
      assert_equal "publisher", result[:publishing_app]
    end

    should "[:rendering_app]" do
      assert_equal "frontend", result[:rendering_app]
    end

    context "for prefix routes" do
      should "[:routes]" do
        edition.stubs(:slug).returns("foo")
        edition.stubs(:exact_route?).returns(false)
        expected = [
          { path: "/foo", type: "prefix" },
        ]
        assert_equal expected, result[:routes]
      end
    end

    context "for exact routes" do
      should "[:routes]" do
        edition.stubs(:slug).returns("foo")
        edition.stubs(:exact_route?).returns(true)
        expected = [
          { path: "/foo", type: "exact" },
        ]
        assert_equal expected, result[:routes]
      end
    end

    should "[:redirects]" do
      assert_equal [], result[:redirects]
    end

    context "[:update_type]" do
      should "return 'republish' if asked" do
        result = subject.render_for_publishing_api(republish: true)
        assert_equal "republish", result[:update_type]
      end

      should "return 'major' if edition.major_change is set" do
        edition.expects(:major_change).returns(true)
        assert_equal "major", result[:update_type]
      end

      should "return 'minor' otherwise" do
        assert_equal "minor", result[:update_type]
      end
    end

    should "[:change_note]" do
      edition.expects(:latest_change_note).returns("foo")
      assert_equal "foo", result[:change_note]
    end

    should "[:details]" do
      assert result[:details].empty?
    end

    should "[:locale]" do
      artefact.expects(:language).returns("foo")
      assert_equal "foo", result[:locale]
    end

    should "[:access_limited]" do
      edition.expects(:auth_bypass_id).returns("foo")
      expected = { auth_bypass_ids: %w[foo] }
      assert_equal expected, result[:access_limited]
    end
  end
end
