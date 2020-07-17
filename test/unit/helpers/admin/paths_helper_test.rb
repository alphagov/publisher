require "test_helper"

class PathsHelperTest < ActionView::TestCase
  JWT_AUTH_SECRET = "111".freeze

  context "#preview_edition_path" do
    setup do
      Rails.stubs(:application).returns(
        stub(
          config: stub(jwt_auth_secret: JWT_AUTH_SECRET),
        ),
      )
    end

    context "when the edition returns an auth_bypass_id" do
      should "append a valid JWT token to the preview path" do
        edition = stub(auth_bypass_id: "123", state: "draft", slug: "foo")
        result = preview_edition_path(edition)

        path = result.gsub(/^(.*)\?.*$/, '\1')
        assert_equal "#{draft_origin}/foo", path

        token = result.gsub(/.*token=(.*)$/, '\1')
        payload = decoded_token_payload(token)

        assert_equal payload["sub"], "123"
      end
    end

    context "when the edition is published" do
      should "not append the JWT token" do
        edition = stub(state: "published", slug: "foo")
        result = preview_edition_path(edition)
        assert_no_match %r{&token=}, result
      end
    end
  end

  def draft_origin
    Plek.current.find("draft-origin")
  end

  def decoded_token_payload(token)
    payload, _header = JWT.decode(
      token,
      JWT_AUTH_SECRET,
      true,
      { algorithm: "HS256" },
    )

    payload
  end
end
