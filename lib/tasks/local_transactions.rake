namespace :local_transactions do
  task :import => :environment do
    puts "Please specify the source file in $SOURCE" and exit(1) unless ENV['SOURCE']

    file = File.open(ENV['SOURCE'], 'r:Windows-1252:UTF-8')

    puts "Importing authorities"
    Authority.populate_from_source!(file)

    puts "Importing sources"
    LocalTransactionsSource.populate_from_source!(file)
  end
end