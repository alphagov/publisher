require_relative '../../test_helper'
require 'redis-lock'

class LocalAuthorityDataImporterTest < ActiveSupport::TestCase

  context "LocalAuthorityDataImporter" do

    should "submit success to nagios if lock not acquired" do
      redis = mock()
      redis.stubs(:lock).raises(Redis::Lock::LockNotAcquired)

      LocalAuthorityDataImporter.expects(:redis).returns(redis)
      LocalAuthorityDataImporter.expects(:nagios_check).with(true, anything).once

      LocalAuthorityDataImporter.update_all
    end

    should "succeed if all update" do
      redis = mock()
      redis.stubs(:lock).yields()

      LocalAuthorityDataImporter.expects(:redis).returns(redis)
      LocalAuthorityDataImporter.expects(:nagios_check).with(true, anything).once

      LocalServiceImporter.expects(:update).once
      LocalInteractionImporter.expects(:update).once
      LocalContactImporter.expects(:update).once

      LocalAuthorityDataImporter.update_all
    end

    should "submit failure if an import fails" do
      redis = mock()
      redis.stubs(:lock).yields()

      LocalAuthorityDataImporter.expects(:redis).returns(redis)
      LocalAuthorityDataImporter.expects(:nagios_check).with(false, anything).once

      LocalServiceImporter.expects(:update).raises(Exception)

      assert_raise Exception do
        LocalAuthorityDataImporter.update_all
      end
    end

    should "throw on !200 when fetching over http" do
      file = mock()
      file.expects(:set_encoding)
      Tempfile.expects(:new).returns(file)

      response = mock()
      response.expects(:code).returns("404").twice

      Net::HTTP.expects(:get_response).returns(response)

      assert_raise RuntimeError do
        LocalAuthorityDataImporter.fetch_http_to_file(
          "http://google.com/lisuhrglser")
      end
    end

    should "pass file handle if 200 when fetching over http" do
      file = mock()
      file.expects(:set_encoding).twice
      file.expects(:write).once
      file.expects(:rewind)

      response = mock()
      response.expects(:code).returns("200").once
      response.expects(:body).returns("luhsglh").once

      Tempfile.expects(:new).returns(file)
      Net::HTTP.expects(:get_response).returns(response)

      out_file = LocalAuthorityDataImporter.fetch_http_to_file(
        "http:/google.com/liuerhgaerg")

      assert_equal(out_file, file)
    end

  end

end
