namespace :local_transactions do
  task :import => :environment do
    puts "Please specify the source file in $SOURCE" and exit(1) unless ENV['SOURCE']

    file = File.open(ENV['SOURCE'], 'r:Windows-1252:UTF-8')

    l = LocalTransactionsImporter.new(file)
    l.run
  end
end