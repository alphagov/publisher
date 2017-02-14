require 'test_helper'

class EditionFormatPresenterTest < ActiveSupport::TestCase
  def subject
    Formats::EditionFormatPresenter.new(edition)
  end

  def edition
    @_edition ||= stub(artefact: artefact)
  end

  def artefact
    @_artefact ||= stub
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
      edition.stubs updated_at: DateTime.now.in_time_zone
      edition.stubs :major_change
      edition.stubs :version_number
      edition.stubs :latest_change_note
      edition.stubs :fact_check_id

      artefact.stubs :kind
      artefact.stubs :language
    end

    should "[:title]" do
      edition.expects(:title).returns('foo')
      assert_equal 'foo', result[:title]
    end

    should "[:base_path]" do
      edition.expects(:slug).returns('foo')
      assert_equal '/foo', result[:base_path]
    end

    context "[:description]" do
      should "return edition.overview if present" do
        edition.expects(:overview).returns('foo')
        assert_equal 'foo', result[:description]
      end

      should "return '' if overview is nil" do
        assert_equal "", result[:description]
      end
    end

    should "[:schema_name]" do
      assert_equal "override me", result[:schema_name]
    end

    should "[:document_type]" do
      artefact.expects(:kind).returns('foo')
      assert_equal 'foo', result[:document_type]
    end

    should "[:need_ids]" do
      assert_equal [], result[:need_ids]
    end

    context "[:public_updated_at]" do
      should "return edition.public_updated_at if not nil" do
        expected = DateTime.now.in_time_zone.rfc3339(3)
        edition.expects(:public_updated_at).returns(expected)
        assert_equal expected, result[:public_updated_at]
      end

      should "return edition.updated_at otherwise" do
        edition.stubs(:public_updated_at).returns(nil)
        expected = DateTime.now.in_time_zone.rfc3339(3)
        edition.expects(:updated_at).returns(expected)
        assert_equal expected, result[:public_updated_at]
      end
    end

    should "[:publishing_app]" do
      assert_equal "publisher", result[:publishing_app]
    end

    should "[:rendering_app]" do
      assert_equal "frontend", result[:rendering_app]
    end

    should "[:routes]" do
      edition.stubs(:slug).returns('foo')
      expected = [
        { path: '/foo', type: 'prefix' },
        { path: '/foo.json', type: 'exact' }
      ]
      assert_equal expected, result[:routes]
    end

    should "[:redirects]" do
      assert_equal [], result[:redirects]
    end

    context "[:update_type]" do
      should "return 'republish' if asked" do
        result = subject.render_for_publishing_api(republish: true)
        assert_equal 'republish', result[:update_type]
      end

      should "return 'major' if edition.major_change is set" do
        edition.expects(:major_change).returns(true)
        assert_equal 'major', result[:update_type]
      end

      should "return 'minor' otherwise" do
        assert_equal 'minor', result[:update_type]
      end
    end

    should "[:change_note]" do
      edition.expects(:latest_change_note).returns('foo')
      assert_equal 'foo', result[:change_note]
    end

    should "[:details]" do
      assert result[:details].empty?
    end

    should "[:locale]" do
      artefact.expects(:language).returns('foo')
      assert_equal 'foo', result[:locale]
    end

    context "[:access_limited]" do
      should "return fact_check_ids if present" do
        edition.expects(:fact_check_id).twice.returns("foo")
        expected = { fact_check_ids: ["foo"] }
        assert_equal expected, result[:access_limited]
      end

      should "not exist if no fact_check_id is present" do
        edition.expects(:fact_check_id).returns(nil)
        refute result.has_key?(:access_limited)
      end
    end
  end
end
