require 'csv'

class Authority
  include Mongoid::Document

  field :snac, type: String
  field :agency_id, type: String
  field :name, type: String

  validates_uniqueness_of :snac, :agency_id, :name
  validates_presence_of :snac, :agency_id, :name
end
