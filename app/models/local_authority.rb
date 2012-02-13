require 'csv'

class LocalAuthority
  include Mongoid::Document

  embeds_many :local_interactions
  
  field :name, type: String
  field :snac, type: String
  field :local_directgov_id, type: Integer
  field :tier, type: String

  validates_uniqueness_of :snac, :local_directgov_id
  validates_presence_of :snac, :local_directgov_id, :name, :tier
  
  scope :for_snacs, ->(snacs) { any_in(snac: snacs) }
  
  def self.find_by_snac(snac)
    for_snacs([snac]).first
  end

  def provides_service?(lgsl_code, lgil_code = nil)
    interactions_for(lgsl_code, lgil_code).any?
  end
  
  def interactions_for(lgsl_code, lgil_code = nil)
    conditions = {lgsl_code: lgsl_code}
    conditions[:lgil_code] = lgil_code if lgil_code
    local_interactions.all_in(conditions)
  end
  
  def preferred_interaction_for(lgsl_code)
    interactions = interactions_for(lgsl_code)
    interactions.excludes(lgil_code: LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION).first ||
      interactions.where(lgil_code: LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION).first
  end
  
end
