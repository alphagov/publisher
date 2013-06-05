require_relative '../test_helper'
require 'local_authority_data_importer'

class LocalAuthorityDataImporterTest < ActiveSupport::TestCase
  def mock_redis(lock_succeeds = true)
    redis = stub()
    if lock_succeeds
      redis.stubs(:lock).yields()
    else
      redis.stubs(:lock).raises(Redis::Lock::LockNotAcquired)
    end
    redis
  end

  context "update_all" do
    setup do
      LocalServiceImporter.stubs(:update)
      LocalInteractionImporter.stubs(:update)
      LocalContactImporter.stubs(:update)
    end

    should "call LocalServiceImporter.update" do
      LocalServiceImporter.expects(:update)
      LocalAuthorityDataImporter.update_all
    end

    should "call LocalInteractionImporter.update" do
      LocalInteractionImporter.expects(:update)
      LocalAuthorityDataImporter.update_all
    end

    should "call LocalContactImporter.update" do
      LocalContactImporter.expects(:update)
      LocalAuthorityDataImporter.update_all
    end

    context "locking" do
      should "obtain a lock before proceeding" do
        redis = mock_redis
        redis.expects(:lock).with("publisher:#{Rails.env}:local_authority_data_importer_lock", :life => (2 * 60 * 60)).yields()
        LocalAuthorityDataImporter.stubs(:redis).returns(redis)

        LocalServiceImporter.expects(:update)

        LocalAuthorityDataImporter.update_all
      end

      should "not update anything if it can't obtain the lock" do
        # Necessary, otherwise the later expects.never calls will never fail
        LocalServiceImporter.unstub(:update)
        LocalInteractionImporter.unstub(:update)
        LocalContactImporter.unstub(:update)

        LocalAuthorityDataImporter.stubs(:redis).returns(mock_redis(false))

        LocalServiceImporter.expects(:update).never
        LocalInteractionImporter.expects(:update).never
        LocalContactImporter.expects(:update).never

        LocalAuthorityDataImporter.update_all
      end
    end
  end
end
