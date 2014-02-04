class ImportImminenceFacetData < Mongoid::Migration
  def self.up
    Rake::Task['business_support_content:import_facet_data'].invoke
  end
end
