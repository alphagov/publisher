require 'test_helper'
require 'local_service_importer'

class LocalServiceImporterTest < ActiveSupport::TestCase
  def fixture_file(file)
    File.expand_path("fixtures/" + file, File.dirname(__FILE__))
  end
  
  context "update" do
    setup do
      LocalServiceImporter.stubs(:new).returns(stub(:run))
    end

    should "create a new instance with a filehandle on the services csv, and run it" do
      stub_fh = stub(:close)
      File.expects(:open).with('data/local_services.csv', 'r:Windows-1252:UTF-8').returns(stub_fh)
      LocalServiceImporter.expects(:new).with(stub_fh).returns(stub(:run))
      LocalServiceImporter.update
    end

    should "run it" do
      instance = stub()
      instance.expects(:run)
      LocalServiceImporter.stubs(:new).returns(instance)
      LocalServiceImporter.update
    end

    should "close the filehandle when done" do
      stub_fh = stub()
      File.stubs(:open).with('data/local_services.csv', anything() ).returns(stub_fh)
      stub_fh.expects(:close)
      LocalServiceImporter.update
    end
  end

  context "CSV of service definitions" do
    setup do
      @sample_csv = File.open(fixture_file('local_services_sample.csv'))
    end
    
    should "import the definitions" do
      assert_difference "LocalService.count" do
        LocalServiceImporter.new(@sample_csv).run
      end
      s = LocalService.first
      assert_equal 'Find out about hazardous waste collection', s.description
      assert_equal 850, s.lgsl_code
      assert_equal %w{county unitary}, s.providing_tier
    end
    
    should "not duplicate definitions if running the import again" do
      LocalServiceImporter.new(@sample_csv).run
      assert_difference "LocalService.count", 0 do
        LocalServiceImporter.new(@sample_csv).run
      end
    end
  end
end
