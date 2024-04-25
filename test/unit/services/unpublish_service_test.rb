require "test_helper"

class UnpublishServiceTest < ActiveSupport::TestCase
  setup do
    @user = stub
    @content_id = "foo"
    @artefact = stub(update_as: true, content_id: @content_id, slug: "foo", state: "live", language: "en", exact_route?: true)
  end

  context "when publishing API returns an error" do
    setup do
      stub_any_publishing_api_unpublish.to_return(status: 422)
    end

    should "not update artefact" do
      @artefact.expects(:update_as).never
      UnpublishService.call(@artefact, @user)
    end

    should "return nil" do
      result = UnpublishService.call(@artefact, @user)
      assert result.nil?
    end
  end

  context "when publishing API is successful" do
    should "update artefact" do
      @artefact.expects(:update_as)
      UnpublishService.call(@artefact, @user)
    end

    context "when no redirect URL is provided" do
      should "archive the artefact in DB" do
        @artefact.expects(:update_as)
                 .with(@user, state: "archived", redirect_url: "")

        UnpublishService.call(@artefact, @user)
      end

      should "tell the publishing API about the change" do
        Services.publishing_api.expects(:unpublish)
                .with(@content_id,
                      locale: "en",
                      type: "gone",
                      discard_drafts: true)

        UnpublishService.call(@artefact, @user)
      end

      should "return true" do
        @artefact.stubs(:update_as).returns(true)
        assert UnpublishService.call(@artefact, @user)
      end
    end

    context "when a valid redirect URL is provided" do
      context "for an artefact with prefix routes" do
        setup do
          @artefact.stubs(:exact_route?).returns(false)
        end
        should "tell the publishing API about the change" do
          Services.publishing_api.expects(:unpublish)
                  .with(@content_id,
                        locale: "en",
                        type: "redirect",
                        redirects: [
                          {
                            path: "/foo",
                            type: "prefix",
                            destination: "/bar",
                            segments_mode: "ignore",
                          },
                        ],
                        discard_drafts: true)

          UnpublishService.call(@artefact, @user, "/bar")
        end
      end

      context "for an artefact with exact routes" do
        setup do
          @artefact.expects(:exact_route?).returns(true)
        end
        should "tell the publishing API about the change" do
          Services.publishing_api.expects(:unpublish)
                  .with(@content_id,
                        locale: "en",
                        type: "redirect",
                        alternative_path: "/bar",
                        discard_drafts: true)

          UnpublishService.call(@artefact, @user, "/bar")
        end
      end

      should "allow a redirect_url to be passed in" do
        @artefact.expects(:update_as)
                 .with(@user, state: "archived", redirect_url: "/bar")

        UnpublishService.call(@artefact, @user, "/bar")
      end

      should "return true" do
        @artefact.stubs(:update_as).returns(true)

        assert UnpublishService.call(@artefact, @user, "/bar")
      end
    end
  end
end
