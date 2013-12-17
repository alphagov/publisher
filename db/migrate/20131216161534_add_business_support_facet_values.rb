class AddBusinessSupportFacetValues < Mongoid::Migration
  def self.up
    load File.join(Rails.root, 'db', 'seeds', 'business_support_facets.rb')
  end
end
