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
        edition = stub(auth_bypass_id: "123", state: "draft", slug: "foo", content_id: "68134a9a-6146-4925-8472-4e3dd42c055a")
        result = preview_edition_path(edition)

        path = result.gsub(/^(.*)\?.*$/, '\1')
        assert_equal "#{draft_origin}/foo", path

        token = result.gsub(/.*token=(.*)$/, '\1')
        payload = decoded_token_payload(token)

        assert_equal payload["sub"], "123"
        assert_equal payload["content_id"], "68134a9a-6146-4925-8472-4e3dd42c055a"
        assert_equal payload["iat"], Time.zone.now.to_i
        assert_equal payload["exp"], 1.month.from_now.to_i
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

  context "#homepage popular links paths" do
    setup do
      Rails.stubs(:application).returns(
        stub(
          config: stub(jwt_auth_secret: JWT_AUTH_SECRET),
        ),
      )
    end

    context "when navigated to preview path" do
      should "append a valid JWT token" do
        popular_links = FactoryBot.build(:popular_links, auth_bypass_id: "8a773f31-3cd2-4bee-9b87-7a9754860094")
        result = preview_homepage_path(popular_links)

        path = result.gsub(/^(.*)\?.*$/, '\1')
        assert_equal draft_origin.to_s, path

        token = result.gsub(/.*token=(.*)$/, '\1')
        payload = decoded_token_payload(token)

        assert_equal payload["sub"], "8a773f31-3cd2-4bee-9b87-7a9754860094"
        assert_equal payload["content_id"], "ad7968d0-0339-40b2-80bc-3ea1db8ef1b7"
        assert_equal payload["iat"], Time.zone.now.to_i
        assert_equal payload["exp"], 1.month.from_now.to_i
      end
    end

    context "when navigated to homepage path" do
      should "not append the JWT token" do
        result = view_homepage_path
        assert_no_match %r{&token=}, result
      end
    end
  end

  def draft_origin
    Plek.find("draft-origin")
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
