require 'csv'

class LocalTransactionsSource
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  has_many :lgsls, class_name: "LocalTransactionsSource::Lgsl"

  def self.populate_from_source!(io)
    source = self.create
    last_row = nil
    begin
      CSV.new(io, :headers => true).each do |row|
        last_row = row
        begin
          lgsl = source.lgsls.find_or_create_by(code: row['lgsl'].to_s)
          authority = lgsl.authorities.find_or_initialize_by(snac: row['snac'])
          authority.lgils.build(code: row['lgil'].to_s, url: row['link'])
          lgsl.save!
        rescue => e
          puts "Failure at row:"
          puts " * #{row.inspect}"
          puts " * #{e.message}"
        end
      end
    rescue => e
      puts "Failure on or immediately after row:"
      puts " * #{last_row.inspect}"
      puts " * #{e.message}"
    end
  end
end
