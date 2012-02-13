require 'csv'

class LocalService
  include Mongoid::Document

  field :description, type: String
  field :lgsl_code, type: Integer
  field :providing_tier, type: Array

  validates_presence_of :lgsl_code, :providing_tier
  validates_uniqueness_of :lgsl_code
  validates :providing_tier, :inclusion => { :in => [%w{county unitary}, %w{district unitary}, %w{district unitary county}] }
  
  def self.find_by_lgsl_code(lgsl_code)
    LocalService.where(lgsl_code: lgsl_code).first
  end
    
  def preferred_interaction(snac_or_snac_list)
    provider = preferred_provider(snac_or_snac_list)
    provider && provider.preferred_interaction_for(lgsl_code)
  end
  
  def preferred_provider(snac_or_snac_list)
    snac_list = [*snac_or_snac_list]
    providers = LocalAuthority.for_snacs(snac_list)
    select_tier(providers)
  end
  
  def provided_by
    LocalAuthority.where('local_interactions.lgsl_code' => lgsl_code).any_in(tier: providing_tier)
  end
  
private

  def select_tier(authorities)
    by_tier = Hash[authorities.map {|a| [a.tier, a]}]
    tier = providing_tier.find { |t| by_tier.has_key?(t) }
    tier && by_tier[tier]
  end
  
end
