namespace :business_support_content do
  desc "Imports Imminence facet data into the corresponding BusinessSupportEdition"
  task :import_facet_data => :environment do
    BusinessSupportFacetDataImporter.run
  end
end
