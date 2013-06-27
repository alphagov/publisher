namespace :local_transaction_expectations do
  desc "Runs :add_wales_only_expectation and :update_local_transaction_regional_expectations tasks"
  task :all => :environment do
    Rake::Task["local_transaction_expectations:add_wales_only_expectation"].invoke
    Rake::Task["local_transaction_expectations:update_local_transaction_regional_expectations"].invoke
  end

  desc "Adds 'Available in Wales only' expectation if it doesn't already exist"
  task :add_wales_only_expectation => :environment do
    Expectation.find_or_create_by(:text => 'Available in Wales only')
  end

  desc %Q(Updates non-archived LocalTransactions with the expectation 
    'Available in England only' to have the expectation 'Available in England and Wales only')
  task :update_local_transaction_regional_expectations => :environment do
    england_only_expectation = Expectation.where(:text => 'Available in England only').first
    england_and_wales_only_expectation = Expectation.where(:text => 'Available in England and Wales only').first
    
    LocalTransactionEdition.excludes(:state => 'archived')
      .any_in(:expectation_ids => [england_only_expectation._id.to_s]).each do |local_transaction|
        unless local_transaction.artefact.archived?
          local_transaction.expectation_ids.delete(england_only_expectation._id.to_s)
          local_transaction.expectation_ids << england_and_wales_only_expectation._id.to_s
          puts "Updated #{local_transaction.title}" if local_transaction.save(:validate => false)
        end
    end
  end
end
