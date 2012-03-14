require 'test_helper'
require_relative '../helpers/local_services_helper'

class LocalTransactionApiGenerationTest < ActiveSupport::TestCase
  include LocalServicesHelper
  #TODO rewrite tests for new branch
  # 
  # def local_transaction_edition_for(lgsl_code)
  #   LocalService.create!(lgsl_code: lgsl_code, providing_tier: %w{county unitary})
  #   local_transaction = LocalTransactionEdition.new(slug: 'test_slug', tags: 'tag, other', :lgsl_code => lgsl_code)
  #   local_transaction.attributes = {version_number: 1, title: 'Test local transaction', updated_at: Time.now}
  #   local_transaction
  # end
  # 
  # setup do
  #   @lgsl_code = 149
  #   @county_council = make_authority('county', snac: 'AA00', lgsl: @lgsl_code)
  #   @edition = local_transaction_edition_for(@lgsl_code)
  # end
  # 
  # def only_keys(hash, keys)
  #   hash.select {|k,v| [*keys].include?(k)}
  # end
  # 
  # context "no snac specified" do
  #   setup { @generated = Api::Generator::edition_to_hash(@edition) }
  #     
  #   should "generate hash with title and slug" do
  #     expected_hash = {
  #       'title' => "Test local transaction",
  #       'slug' => "test_slug"
  #     }
  #   
  #     assert_equal expected_hash, only_keys(@generated, %w{title slug})
  #   end
  # end
  # 
  # context "snac specified" do
  #   setup do
  #     @generated = Api::Generator::edition_to_hash(@edition, :snac => @county_council.snac)
  #   end
  #   
  #   should "also include description of service interaction and authority" do
  #     assert @generated.has_key?('interaction')
  #     
  #     expected_interaction_description = {
  #       'url' => "http://some.county.council.gov/do-#{@lgsl_code}.html",
  #       'lgil_code' => 0,
  #       'lgsl_code' => @lgsl_code,
  #       'authority' => {
  #         'name' => @county_council.name,
  #         'snac' => @county_council.snac,
  #         'tier' => @county_council.tier
  #       }
  #     }
  # 
  #     assert_equal expected_interaction_description, @generated['interaction']
  #   end
  # end
  # 
  # context "snac exists but doesn't have that interaction" do
  #   setup do
  #     @edition2 = local_transaction_edition_for(@lgsl_code + 1)
  #   end
  #   
  #   should "an empty interaction" do
  #     generated = Api::Generator::edition_to_hash(@edition2, :snac => @county_council.snac)
  # 
  #     assert_equal nil, generated['interaction']
  #   end
  # end
  # 
  # context "all interactions requested" do
  #   setup do
  #     @council2 = make_authority('county', snac: 'BB00', lgsl: @lgsl_code)
  #     make_authority('county', snac: 'CC00', lgsl: @lgsl_code.to_i + 1)
  #     @generated = Api::Generator::edition_to_hash(@edition, :all => true)
  #   end
  #   
  #   should_eventually "also include description of service interaction and authority" do
  #     # We suspect that this feature is not currently used anywhere, and not exposed
  #     # through the public api.
  #     assert @generated.has_key?('interactions')
  #     
  #     interactions = []
  #     interactions << {
  #       'url' => "http://some.county.council.gov/do-#{@lgsl_code}.html",
  #       'lgil_code' => "0",
  #       'lgsl_code' => @lgsl_code,
  #       'authority' => {
  #         'name' => @county_council.name,
  #         'snac' => @county_council.snac,
  #         'tier' => @county_council.tier
  #       }
  #     }
  # 
  #     interactions << {
  #       'url' => "http://some.county.council.gov/do-#{@lgsl_code}.html",
  #       'lgil_code' => "0",
  #       'lgsl_code' => @lgsl_code,
  #       'authority' => {
  #         'name' => @council2.name,
  #         'snac' => @council2.snac,
  #         'tier' => @council2.tier
  #       }
  #     }
  # 
  #     assert_equal interactions, @generated['interactions']
  #   end
  # end    
  # 
end