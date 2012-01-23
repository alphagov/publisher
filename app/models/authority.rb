require 'csv'

class Authority
  include Mongoid::Document

  field :snac, type: String
  field :agency_id, type: String
  field :name, type: String

  validates_uniqueness_of :snac, :agency_id, :name
  validates_presence_of :snac, :agency_id, :name

  def self.populate_from_source!(io)
    CSV.new(io, headers: true).each do |row|
      begin
        authority = Authority.find_or_initialize_by(snac: row['SNAC'])
        authority.name = row['Authority Name']
        authority.agency_id = row['LAid']
        authority.save!
      rescue => e
        puts "Failure at row:"
        puts " * #{row.inspect}"
        puts " * #{e.message}"
      end
    end
  end
end
