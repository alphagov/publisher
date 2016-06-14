require 'test_helper'
require 'local_contact_importer'

class LocalContactImporterTest < ActiveSupport::TestCase

  def fixture_file(file)
    File.expand_path("fixtures/" + file, File.dirname(__FILE__))
  end

  context "update" do
    setup do
      LocalContactImporter.stubs(:new).returns(stub(:run))
    end

    should "download the data" do
      LocalContactImporter.expects(:fetch_data).returns(stub(:close))
      LocalContactImporter.update
    end

    should "pass the download filehandle to a new instance of self, and run self" do
      stub_fh = stub(:close)
      LocalContactImporter.stubs(:fetch_data).returns(stub_fh)
      LocalContactImporter.expects(:new).with(stub_fh).returns(stub(:run))
      LocalContactImporter.update
    end

    should "close the filehandle when done" do
      stub_fh = stub()
      LocalContactImporter.stubs(:fetch_data).returns(stub_fh)
      stub_fh.expects(:close)
      LocalContactImporter.update
    end
  end

  context "fetch_data" do
    should "download the csv file and return a filehandle containing the data" do
      stub_request(:get, "http://local.direct.gov.uk/Data/local_authority_contact_details.csv").
        to_return(:status => 200, :body => "Example Contacts CSV Content")

      filehandle = LocalContactImporter.fetch_data
      data = filehandle.read
      assert_equal "Example Contacts CSV Content", data

      filehandle.close
    end
  end

  context "processing CSV of contact details" do
    should "Update existing authorities from file, and skip any non-existent ones." do
      source = File.open(fixture_file('local_contacts_sample.csv'))

      auth2 = FactoryGirl.create(:local_authority, :name => "Allerdale", :snac => "16UB")
      auth3 = FactoryGirl.create(:local_authority, :name => "Allerdale", :snac => "22UB")

      LocalContactImporter.new(source).run

      assert_nil LocalAuthority.find_by_snac("45UB")

      auth2.reload
      assert_equal "Allerdale Borough Council", auth2.name
      assert_equal "http://www.allerdale.gov.uk", auth2.homepage_url

      auth3 = LocalAuthority.find_by_snac("22UB")
      assert_equal "Basildon District Council", auth3.name
      assert_equal "http://www.basildon.gov.uk/", auth3.homepage_url

      assert_equal 2, LocalAuthority.count
    end

    should "handle HTML entities in authority names" do
      source = StringIO.new(<<-END)
Name,Home page URL,Contact page URL,SNAC Code,Address Line 1,Address Line 2,Town,City,County,Postcode,Telephone Number 1 Description,Telephone Number 1,Telephone Number 2 Description,Telephone Number 2,Telephone Number 3 Description,Telephone Number 3,Fax,Main Contact Email,Opening Hours
Bedford Council &#40 Unitary&#41,http://www.bedford.gov.uk/,http://www.bedford.gov.uk/findus,00KB,Bedford Borough Council,Borough Hall,Cauldwell Street,Bedford.,,MK42 9AP,,01234 267422,Textphone,,,,01234 221606,centralp@bedford.gov.uk,
      END

      auth = FactoryGirl.create(:local_authority, :snac => "00KB")

      LocalContactImporter.new(source).run

      auth.reload
      assert_equal "Bedford Council ( Unitary)", auth.name
    end

    should "add http:// to URLs without it" do
      source=StringIO.new(<<-END)
Name,Home page URL,Contact page URL,SNAC Code,Address Line 1,Address Line 2,Town,City,County,Postcode,Telephone Number 1 Description,Telephone Number 1,Telephone Number 2 Description,Telephone Number 2,Telephone Number 3 Description,Telephone Number 3,Fax,Main Contact Email,Opening Hours
South Somerset District Council,www.southsomerset.gov.uk,www.southsomerset.gov.uk/get-in-touch,40UD,Council Offices,Brympton Way,Yeovil,,Somerset,BA20 2HT,,01935 462 462,,,,,,,
      END

      auth = FactoryGirl.create(:local_authority, :snac => "40UD")
      # Call process_row directly to bypass the top-level error rescue
      importer = LocalContactImporter.new(nil)
      csv = CSV.new(source, :headers => true)
      importer.send(:process_row, csv.shift)

      auth.reload
      assert_equal "http://www.southsomerset.gov.uk", auth.homepage_url
    end

    should "handle missing homepage URLs" do
      source=StringIO.new(<<-END)
Name,Home page URL,Contact page URL,SNAC Code,Address Line 1,Address Line 2,Town,City,County,Postcode,Telephone Number 1 Description,Telephone Number 1,Telephone Number 2 Description,Telephone Number 2,Telephone Number 3 Description,Telephone Number 3,Fax,Main Contact Email,Opening Hours
South Somerset District Council,,http://www.southsomerset.gov.uk/get-in-touch/,40UD,Council Offices,Brympton Way,Yeovil,,Somerset,BA20 2HT,,01935 462 462,,,,,,,
      END

      auth = FactoryGirl.create(:local_authority, :snac => "40UD")
      # Call process_row directly to bypass the top-level error rescue
      importer = LocalContactImporter.new(nil)
      csv = CSV.new(source, :headers => true)
      importer.send(:process_row, csv.shift)

      auth.reload
      assert_equal nil, auth.homepage_url
    end
  end
end
