require 'test_helper'

class LocalTransactionTest < ActiveSupport::TestCase
  #TODO rewrite tests for new branch
  # def create_authority_providing(service_lgsl)
  #   county_council = LocalAuthority.create(
  #     name: "Some County Council", 
  #     snac: '00AA', 
  #     local_directgov_id: 1, 
  #     tier: 'county',
  #     homepage_url: 'http://some.county.council.gov/',
  #     contact_url: 'http://some.county.council.gov/contact.html'
  #   )
  #   county_council.local_interactions.create!(
  #     url: 'http://some.county.council.gov/do.html',
  #     lgsl_code: service_lgsl,
  #     lgil_code: 0)
  #   county_council
  # end
  # 
  # context "a local transaction for the 'bins' service" do
  #   setup do
  #     @lgsl_code = 'bins'
  #     @bins_transaction = LocalTransactionEdition.new(lgsl_code: @lgsl_code, name: "Transaction", slug: "slug")
  #   end
  #   
  #   context "an authority exists providing the 'housing-benefit' service" do
  #     setup { @county_council = create_authority_providing('housing-benefit') }
  # 
  #     should "report that that authority does not provide the bins service" do
  #       assert ! @bins_transaction.service_provided_by?(@county_council.snac)
  #     end
  #   end
  #   
  #   context "an authority exists providing 'bins' service" do
  #     setup { @county_council = create_authority_providing('bins') }
  #   
  #     should "report that that authority provides the bins service" do
  #       assert @bins_transaction.service_provided_by?(@county_council.snac)
  #     end
  # 
  #     should "report that some other authority does not provide the bins service" do
  #       assert ! @bins_transaction.service_provided_by?('some_other_snac')
  #     end
  #   end
  # 
  #   should "report the search_format to be 'transaction'" do
  #     assert_equal "transaction", @bins_transaction.search_format
  #   end
  # end
  # 
  # context "when saving" do
  #   should "validate that a LocalService exists for that lgsl_code" do
  #     s = LocalService.create!(lgsl_code: 'bins', providing_tier: %w{county unitary})
  # 
  #     lt = LocalTransactionEdition.new(lgsl_code: 'nonexistent', name: "Foo", slug: "foo")
  #     lt.save
  #     assert !lt.valid?
  #     
  #     lt = LocalTransactionEdition.new(lgsl_code: s.lgsl_code, name: "Bar", slug: "bar")
  #     lt.save
  #     assert lt.valid?
  #     assert lt.persisted?
  #   end
  # end
end