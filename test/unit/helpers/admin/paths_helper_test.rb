require 'test_helper'

class PathsHelperTest < ActionView::TestCase
  context "#preview_edition_path" do
    context "for migrated formats" do
      should "return path for draft stack" do
        edition = stub(version_number: 1, migrated?: true, id: 999, slug: "for-funzies")
        expected_path = "#{draft_origin}/for-funzies?cache=1234"
        assert_equal expected_path, preview_edition_path(edition, 1234)
      end
    end

    context "for non-migrated formats" do
      should "return path for private frontend" do
        edition = stub(version_number: 1, migrated?: false, id: 999, slug: "for-funzies")
        expected_path = "#{private_frontend}/for-funzies?edition=1&cache=9876"
        assert_equal expected_path, preview_edition_path(edition, 9876)
      end
    end
  end

  context "#fact_check_edition_path" do
    setup do
      Rails.stubs(:application).returns(
        stub(
          config: stub(
            jwt_auth_secret: '111'
          )
        )
      )
    end

    context "when the edition returns a fact_check_id" do
      should "append a valid JWT token to the preview path" do
        edition = stub(fact_check_id: '123', migrated?: true, slug: 'foo')
        result = fact_check_edition_path(edition)

        path = result.gsub(/^(.*)\?cache=.*&token=.*$/, '\1')
        assert_equal "#{draft_origin}/foo", path

        token = result.gsub(/.*token=(.*)$/, '\1')
        jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.qev-lRek9IUTvoMW1Hx2KUDUmmbnAVXzoFJL1Gvm0pg"
        assert_equal jwt, token
      end
    end

    context "when the edition doesn't return a fact_check_id" do
      should "not append the JWT token" do
        edition = stub(fact_check_id: nil, migrated?: true, slug: 'foo')
        result = fact_check_edition_path(edition)
        assert_no_match %r(&token=), result
      end
    end
  end

  def draft_origin
    Plek.current.find("draft-origin")
  end

  def private_frontend
    Plek.current.find("private-frontend")
  end
end
