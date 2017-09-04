require 'test_helper'

class UnpublishServiceTest < ActiveSupport::TestCase
  setup do
    @content_id = 'foo'
    @edition = stub(exact_route?: true)
    @artefact = stub(update_attributes_as: true, content_id: @content_id, slug: "foo", state: "live", language: "en", latest_edition: @edition)
    @user = stub
    @publishing_api = stub(unpublish: true)

    Services.stubs(:publishing_api).returns(@publishing_api)
  end

  context "when an invalid redirect URL is provided" do
    should "Publishing API is not called" do
      @artefact.expects(:update_attributes_as).returns(false)
      @publishing_api.expects(:unpublish).never

      UnpublishService.call(@artefact, @user)
    end

    should "return nil" do
      @artefact.expects(:update_attributes_as).returns(false)

      result = UnpublishService.call(@artefact, @user)
      assert result == nil
    end
  end

  context "when no redirect URL is provided" do
    should "archive the artefact" do
      @artefact.expects(:update_attributes_as)
        .with(@user, state: 'archived', redirect_url: "")
        .returns(true)

      UnpublishService.call(@artefact, @user)
    end

    should "tell the publishing API about the change" do
      @publishing_api.expects(:unpublish)
        .with(@content_id,
              locale: "en",
              type: 'gone',
              discard_drafts: true)
        .returns(true)

      UnpublishService.call(@artefact, @user)
    end

    should "return true" do
      @artefact.expects(:update_attributes_as).returns(true)

      assert UnpublishService.call(@artefact, @user)
    end
  end

  context "when a valid redirect URL is provided" do
    context "for an artefact with prefix routes" do
      should "tell the publishing API about the change" do
        @edition.expects(:exact_route?).returns(false)

        @publishing_api.expects(:unpublish)
          .with(@content_id,
                locale: "en",
                type: 'redirect',
                redirects: [
                  {
                    path: "/foo",
                    type: 'prefix',
                    destination: '/bar'
                  }
                ],
                discard_drafts: true)
          .returns(true)

        UnpublishService.call(@artefact, @user, '/bar')
      end
    end

    context "for an artefact with exact routes" do
      should "tell the publishing API about the change" do
        @publishing_api.expects(:unpublish)
          .with(@content_id,
                locale: "en",
                type: 'redirect',
                alternative_path: '/bar',
                discard_drafts: true)
          .returns(true)

        UnpublishService.call(@artefact, @user, '/bar')
      end
    end

    should "allow a redirect_url to be passed in" do
      @artefact.expects(:update_attributes_as)
        .with(@user, state: 'archived', redirect_url: '/bar')
        .returns(true)

      UnpublishService.call(@artefact, @user, "/bar")
    end

    should "return true" do
      @artefact.expects(:update_attributes_as).returns(true)

      assert UnpublishService.call(@artefact, @user, '/bar')
    end
  end
end
