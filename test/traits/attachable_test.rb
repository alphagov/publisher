require 'test_helper'

class ModelWithAttachments
  include Attachable
  include Mongoid::Document

  field :title, type: String
  attaches :image
end

class ModelWithAttachmentsAndUrl
  include Attachable
  include Mongoid::Document

  field :title, type: String
  attaches :image, with_url_field: true
end

class ModelWithUpdatableAttachments
  include Attachable
  include Mongoid::Document

  field :title, type: String
  attaches :image, update_existing: true, with_url_field: true
end

class AttachableTest < ActiveSupport::TestCase

  setup do
    @edition = ModelWithAttachments.new
    @edition_with_url_field = ModelWithAttachmentsAndUrl.new
    @edition_with_update_option = ModelWithUpdatableAttachments.new
    @previous_api_client = Attachable.asset_api_client
    @mock_asset_api = mock("mock_asset_api")
    Attachable.asset_api_client = @mock_asset_api
  end

  teardown do
    Attachable.asset_api_client = @previous_api_client
  end

  context "retreiving assets from the api" do
    should "raise an exception if there is no api client present" do
      Attachable.asset_api_client = nil

      @edition.image_id = "an_image_id"
      assert_raise Attachable::ApiClientNotPresent do
        @edition.image.file_url
      end
    end

    should "make the request to the asset api" do
      @edition.image_id = "an_image_id"

      asset = { "file_url" => "/path/to/image" }
      @mock_asset_api.expects(:asset).with("an_image_id").returns(asset)

      assert_equal "/path/to/image", @edition.image["file_url"]
    end

    should "cache the asset from the api" do
      @edition.image_id = "an_image_id"

      asset = { "something" => "one", "something_else" => "two" }
      @mock_asset_api.expects(:asset).once.with("an_image_id").returns(asset)

      assert_equal "one", @edition.image["something"]
      assert_equal "two", @edition.image["something_else"]
    end

    should "assign a file and detect it has changed" do
      file = File.open(File.expand_path("../../fixtures/uploads/image.jpg", __FILE__))
      @edition.image = file
      assert @edition.image_has_changed?
    end
  end

  context "saving an edition without update_existing set" do
    setup do
      @file = File.open(File.expand_path("../../fixtures/uploads/image.jpg", __FILE__))
      @asset = {
        "id" => 'http://asset-manager.dev.gov.uk/assets/an_image_id',
        "file_url" => 'http://asset-manager.dev.gov.uk/media/an_image_id/image.jpg'
      }
    end

    should "create another asset even if an asset already exists" do
      @edition.image_id = "foo"
      @mock_asset_api.expects(:create_asset).returns(@asset)

      @edition.image = @file
      @edition.save!
    end

    should "create an asset when one does not exist" do
      @mock_asset_api.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition.image = @file
      @edition.save!
    end

    should "not upload an asset if it has not changed" do
      @edition.save!
    end

    should "assign the asset id to the attachment id attribute" do
      @mock_asset_api.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition.image = @file
      @edition.save!

      assert_equal "an_image_id", @edition.image_id
    end

    should "assign the asset url to the attachment url attribute if requested" do
      @mock_asset_api.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition_with_url_field.image = @file
      @edition_with_url_field.save!
      assert_equal 'http://asset-manager.dev.gov.uk/media/an_image_id/image.jpg', @edition_with_url_field["image_url"]
    end

    should "not create the attachment url attribute if not requested" do
      @mock_asset_api.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition.image = @file
      @edition.save!

      refute @edition.respond_to?(:image_url)
    end

    should "raise an exception if there is no api client present" do
      Attachable.asset_api_client = nil

      @edition.image = @file
      assert_raise Attachable::ApiClientNotPresent do
        @edition.save!
      end
    end

    should "catch any errors raised by the api client" do
      @mock_asset_api.expects(:create_asset).raises(StandardError)

      assert_nothing_raised do
        @edition.image = @file
        @edition.save!
      end

      assert_equal ["could not be uploaded"], @edition.errors[:image_id]
    end

    should "not stop the edition from being saved when an uploading error is raised" do
      @mock_asset_api.expects(:create_asset).raises(StandardError)

      @edition.image = @file
      @edition.title = "foo"
      @edition.save!

      @edition.reload
      assert_equal "foo", @edition.title
    end
  end

  context "removing an asset" do
    should "remove an asset when remove_* set to true" do
      @edition.image_id = 'an_image_id'
      @edition.remove_image = true
      @edition.save!

      assert_nil @edition.image_id
    end

    should "not remove an asset when remove_* set to false or empty" do
      @edition.image_id = 'an_image_id'
      @edition.remove_image = false
      @edition.remove_image = ""
      @edition.remove_image = nil
      @edition.save!

      assert_equal "an_image_id", @edition.image_id
    end
  end

  context "with update_existing option set" do
    setup do
      @file = File.open(File.expand_path("../../fixtures/uploads/image.jpg", __FILE__))

      @asset_id = 'an_image_id'

      @asset_response = {
        "id" => "http://asset-manager.dev.gov.uk/assets/#{@asset_id}",
        "file_url" => 'http://asset-manager.dev.gov.uk/media/an_image_id/image.jpg'
      }
    end

    context "saving an edition without an existing asset" do
      should "create a new asset" do
        @mock_asset_api.expects(:create_asset).with(:file => @file).returns(@asset_response)

        @edition_with_update_option.image = @file
        @edition_with_update_option.save!
      end

      should "assign the asset id and file url" do
        @mock_asset_api.stubs(:create_asset).returns(@asset_response)

        @edition_with_update_option.image = @file
        @edition_with_update_option.save!

        assert_equal @asset_id, @edition_with_update_option.image_id
        assert_equal @asset_response["file_url"], @edition_with_update_option.image_url
      end
    end

    context "saving an edition with and existing asset" do
      setup do
        @existing_asset = {
          "id" => "http://asset-manager.dev.gov.uk/assets/#{@asset_id}",
          "file_url" => 'http://asset-manager.dev.gov.uk/media/an_image_id/old_image.jpg'
        }

        @edition_with_update_option.image_id = @asset_id
        @edition_with_update_option.image_url = @existing_asset["file_url"]
      end

      should "update the asset on save" do
        @mock_asset_api.expects(:update_asset).with(@asset_id, :file => @file).returns(@asset_response)

        @edition_with_update_option.image = @file
        @edition_with_update_option.save!
      end

      should "update the file url for the asset" do
        @mock_asset_api.stubs(:update_asset).returns(@asset_response)

        @edition_with_update_option.image = @file
        @edition_with_update_option.save!

        assert_equal @asset_response["file_url"], @edition_with_update_option.image_url
      end
    end
  end
end
