
require 'test_helper'
require 'local_interaction_importer'
require_relative 'helpers/local_services_helper'

class LocalInteractionImporterTest < ActiveSupport::TestCase
  include LocalServicesHelper
  
  def fixture_file(file)
    File.expand_path("fixtures/" + file, File.dirname(__FILE__))
  end
  
  def read_fixture_file(file)
    File.read(fixture_file(file))
  end
  
  def setup
    stub_request(:get, "http://mapit.mysociety.org/area/45UB").
      to_return(status: 404, body: '{}')
  end
  
  context "update" do
    setup do
      LocalInteractionImporter.stubs(:new).returns(stub(:run))
    end

    should "download the data" do
      LocalInteractionImporter.expects(:fetch_data).returns(stub(:close))
      LocalInteractionImporter.update
    end

    should "pass the download filehandle to a new instance of self, and run self" do
      stub_fh = stub(:close)
      LocalInteractionImporter.stubs(:fetch_data).returns(stub_fh)
      LocalInteractionImporter.expects(:new).with(stub_fh).returns(stub(:run))
      LocalInteractionImporter.update
    end

    should "close the filehandle when done" do
      stub_fh = stub()
      LocalInteractionImporter.stubs(:fetch_data).returns(stub_fh)
      stub_fh.expects(:close)
      LocalInteractionImporter.update
    end
  end

  context "fetch_data" do
    should "download the csv file and return a filehandle containing the data" do
      stub_request(:get, "http://local.direct.gov.uk/Data/local_authority_service_details.csv").
        to_return(:status => 200, :body => "Example Interactions CSV Content")

      filehandle = LocalInteractionImporter.fetch_data
      data = filehandle.read
      assert_equal "Example Interactions CSV Content", data

      filehandle.close
    end
  end

  context "CSV of interaction definitions with one row" do
    setup do
      @source = File.open(fixture_file('local_interactions_sample.csv'))
    end
    
    context "Local authority already known" do
      setup do
        @authority = make_authority('county', snac: '45UB')
      end
      
      should "Add one interaction to that authority" do
        assert_difference "@authority.reload.local_interactions.count" do
          LocalInteractionImporter.new(@source).run
        end
        interaction = @authority.reload.local_interactions.first
        assert_equal "http://www.adur.gov.uk/education/index.htm", interaction.url
        assert_equal 18, interaction.lgsl_code
        assert_equal 8, interaction.lgil_code
      end
      
      context "interaction already defined" do
        setup do
          @authority.local_interactions.create!(
            url: "http://www.adur.gov.uk/education/index-old.htm",
            lgsl_code: 18,
            lgil_code: 8)
        end
        
        should "update the url" do
          assert_no_difference "@authority.reload.local_interactions.count" do
            LocalInteractionImporter.new(@source).run
          end
          interaction = @authority.reload.local_interactions.first
          assert_equal "http://www.adur.gov.uk/education/index.htm", interaction.url
        end
      end
    end
    
    context "Local authority not already known" do
      should "Create a new authority" do
        assert_difference "LocalAuthority.count" do
          LocalInteractionImporter.new(@source).run
        end
        authority = LocalAuthority.first
        assert_equal "Adur District Council", authority.name
        assert_equal "45UB", authority.snac
        assert_equal 1, authority.local_directgov_id
      end
      
      should "Lookup tier from mapit" do
        stub_request(:get, "http://mapit.mysociety.org/area/45UB")
          .to_return(status: 200, body: read_fixture_file('mapit_response.json'))
        LocalInteractionImporter.new(@source).run
        assert_equal 'district', LocalAuthority.first.tier
      end
    end
    
  end
  
end
