require 'test_helper'

class PathsHelperTest < ActionView::TestCase
  context "#preview_edition_path" do
    setup do
      Rails.stubs(:application).returns(
        stub(
          config: stub(
            jwt_auth_secret: '111'
          )
        )
      )
    end

    context "when the edition returns an auth_bypass_id" do
      should "append a valid JWT token to the preview path" do
        edition = stub(auth_bypass_id: '123', migrated?: true, state: 'draft', slug: 'foo')
        result = preview_edition_path(edition)

        path = result.gsub(/^(.*)\?.*$/, '\1')
        assert_equal "#{draft_origin}/foo", path

        token = result.gsub(/.*token=(.*)$/, '\1')
        jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.qev-lRek9IUTvoMW1Hx2KUDUmmbnAVXzoFJL1Gvm0pg"
        assert_equal jwt, token
      end
    end

    context "when the edition is published" do
      should "not append the JWT token" do
        edition = stub(migrated?: true, state: 'published', slug: 'foo')
        result = preview_edition_path(edition)
        assert_no_match %r(&token=), result
      end
    end
  end

  def draft_origin
    Plek.current.find("draft-origin")
  end
end
