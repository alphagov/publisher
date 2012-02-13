require 'test_helper'
require_relative 'helpers/local_services_helper'

class LocalServiceTest < ActiveSupport::TestCase
  include LocalServicesHelper
  
  def assert_same_authorities(expected, actual, message = nil)
    assert_equal expected.map(&:snac).sort, actual.map(&:snac).sort, message
  end
  
  def assert_excluded(excluded, actual, message = nil)
    actual_snacs = actual.map(&:snac)
    excluded.each do |x|
      assert ! actual_snacs.include?(x), "'#{actual_snacs}' should not contain '#{x}'"
    end
  end
  
  def setup
    LocalAuthority.delete_all
    @lgsl_code = 123
    @snac_code = 'AA00'
    @county_council = make_authority('county', snac: 'AA00', lgsl: @lgsl_code)
    @district_council = make_authority('district', snac: 'AA', lgsl: @lgsl_code)
    @unitary_authority = make_authority('unitary', snac: 'BB00', lgsl: @lgsl_code)
  end

  context "service is provided by county/unitary authority" do
    setup do
      @service = LocalService.create!(lgsl_code: @lgsl_code, providing_tier: %w{county unitary})
    end
    
    context "location has county and district councils" do
      setup { @councils = [@county_council.snac, @district_council.snac] }
    
      should "return the url from the county council" do
        assert_equal "http://some.county.council.gov/do-123.html", @service.preferred_interaction(@councils).url
      end
    end
    
    context "location has unitary authority" do
      setup { @councils = [@unitary_authority.snac] }

      should "return the url from the unitary authority" do      
        assert_equal "http://some.unitary.council.gov/do-123.html", @service.preferred_interaction(@councils).url
      end
    end

    context "location has only district council" do
      setup { @councils = [@district_council.snac] }
    
      should "return nil" do
        assert_nil @service.preferred_interaction(@councils)
      end
    end

    context "listing all providers" do
      setup do
        other_service = @service.lgsl_code.to_i + 1
        add_service_interaction(@county_council, other_service)
        make_authority('county', snac: 'CC00', lgsl: other_service)
        make_authority('unitary', snac: 'CC01', lgsl: other_service)
      end
      
      should "exclude county and unitary authorities providing other services, but not this one" do
        assert_excluded ['CC01', 'CC00'], @service.provided_by
      end
      
      should "return only county or unitary authorities" do
        assert_same_authorities [@county_council, @unitary_authority], @service.provided_by
      end
    end

  end
  
  context "service is provided by district/unitary authority" do
    setup do
      @service = LocalService.create!(lgsl_code: @lgsl_code, providing_tier: %w{district unitary})
    end
    
    context "location has county and district councils" do
      setup { @councils = [@county_council.snac, @district_council.snac] }
    
      should "return the url from the district council" do
        assert_equal "http://some.district.council.gov/do-123.html", @service.preferred_interaction(@councils).url
      end
    end
    
    context "location has unitary authority" do
      setup { @councils = [@unitary_authority.snac] }

      should "return the url from the unitary authority" do      
        assert_match "http://some.unitary.council.gov/do-123.html", @service.preferred_interaction(@councils).url
      end
    end

    context "location has only county council" do
      setup { @councils = [@county_council.snac] }
    
      should "return nil" do
        assert_nil @service.preferred_interaction(@councils)
      end
    end

    context "listing all providers" do
      should "return only district or unitary authorities" do
        assert_same_authorities [@district_council, @unitary_authority], @service.provided_by
      end
    end
  end
  
  context "service is provided by both tiers" do
    setup do
      @service = LocalService.create!(lgsl_code: @lgsl_code, providing_tier: %w{district unitary county})
    end

    context "location has county and district councils" do
      setup { @councils = [@county_council.snac, @district_council.snac] }
    
      should "returns the url of the service provided by the district council" do
        url = @service.preferred_interaction(@councils).url
        assert_equal "http://some.district.council.gov/do-123.html", url
      end
    end

    context "location has unitary authority" do
      setup { @councils = [@unitary_authority.snac] }
    
      should "returns the url of the service provided by the unitary authority" do
        url = @service.preferred_interaction(@councils).url
        assert_equal "http://some.unitary.council.gov/do-123.html", url
      end
    end
    
    context "location has only county council" do
      # This shouldn't really ever happen and suggests that the data
      # is incorrect somehow, but we might as well fall back to county council
      setup { @councils = [@county_council.snac] }
      
      should "return the url of the service provided by the county council" do
        url = @service.preferred_interaction(@councils).url
        assert_equal "http://some.county.council.gov/do-123.html", url
      end
    end
    
    context "listing all providers" do
      should "return all authorities providing that service" do
        make_authority('county', snac: 'CC00', lgsl: 124)
        assert_same_authorities [@county_council, @district_council, @unitary_authority], @service.provided_by
      end
    end
  end
  
end
