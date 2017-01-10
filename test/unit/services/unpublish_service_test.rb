require 'test_helper'

class UnpublishServiceTest < ActiveSupport::TestCase
  setup do
    @content_id = 'foo'
    @artefact = stub(update_attributes_as: true, content_id: @content_id, slug: "foo", state: "live")
    @user = stub
    @publishing_api = stub(unpublish: true)
    @router_api = stub(:submit)

    RemoveFromSearch.stubs(:call)
    RoutableArtefact.stubs(:new).returns(@router_api)
    Services.stubs(:publishing_api).returns(@publishing_api)
  end

  context "when an invalid redirect URL is provided" do
    should "Rummager is not called" do
      @artefact.expects(:update_attributes_as).returns(false)
      RemoveFromSearch.expects(:call).never

      UnpublishService.call(@artefact, @user)
    end

    should "Router API is not called" do
      @artefact.expects(:update_attributes_as).returns(false)
      @router_api.expects(:submit).never

      UnpublishService.call(@artefact, @user)
    end

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

    should "remove the artefact from Rummager search" do
      RemoveFromSearch.expects(:call).with(@artefact.slug)
      UnpublishService.call(@artefact, @user)
    end

    should "add gone route to router_api" do
      @router_api.expects(:submit)

      UnpublishService.call(@artefact, @user)
    end

    should "tell the publishing API about the change" do
      @publishing_api.expects(:unpublish)
        .with(@content_id, type: 'gone', discard_drafts: true)
        .returns(true)

      UnpublishService.call(@artefact, @user)
    end

    should "return true" do
      @artefact.expects(:update_attributes_as).returns(true)

      assert UnpublishService.call(@artefact, @user)
    end
  end

  context "when a valid redirect URL is provided" do
    should "remove the artefact from Rummager search" do
      RemoveFromSearch.expects(:call).with(@artefact.slug)
      UnpublishService.call(@artefact, @user)
    end

    should "tell the publishing API about the change" do
      @publishing_api.expects(:unpublish)
        .with(@content_id, type: 'redirect', alternative_path: '/bar', discard_drafts: true)
        .returns(true)

      UnpublishService.call(@artefact, @user, '/bar')
    end

    should "allow a redirect_url to be passed in" do
      @artefact.expects(:update_attributes_as)
        .with(@user, state: 'archived', redirect_url: '/bar')
        .returns(true)

      UnpublishService.call(@artefact, @user, "/bar")
    end

    should "add gone route to router_api" do
      @router_api.expects(:submit)

      UnpublishService.call(@artefact, @user, '/bar')
    end

    should "return true" do
      @artefact.expects(:update_attributes_as).returns(true)

      assert UnpublishService.call(@artefact, @user, '/bar')
    end
  end

  context "when an artefact is already archived" do
    should "return false early" do
      @artefact.expects(:state).returns("archived")
      @artefact.expects(:update_attributes_as).never
      RemoveFromSearch.expects(:call).never
      @router_api.expects(:submit).never
      @publishing_api.expects(:unpublish).never

      result = UnpublishService.call(@artefact, @user)
      assert result == false
    end
  end
end
