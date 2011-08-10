require 'csv'

class Authority
  include Mongoid::Document

  field :snac, type: String
  field :agency_id, type: String
  field :name, type: String

  validates_uniqueness_of :snac, :agency_id, :name
  validates_presence_of :snac, :agency_id, :name

  def self.populate_from_source!(io)
    begin
      CSV.new(io, headers: true).each do |row|
        puts row
        authority = Authority.find_or_initialize_by(snac: row['snac'])
        authority.name = row['agency_name']
        authority.agency_id = row['agency_id']
        authority.save!
      end
    rescue => e
      puts "Failure at row:"
      puts " * #{row.inspect}"
      puts " * #{e.message}"
    end
  end
end
