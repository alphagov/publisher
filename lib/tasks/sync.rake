namespace :sync do
  desc "Sync publication data to Need-O-Tron"
  task :created => :environment do                      
    count = 0
    Publication.all.each do |pub|                    
      Messenger.instance.send 'created', pub 
      count += 1
      puts "[#{count}] #{pub.name} pushed to queue"
    end         
    puts "Total records pushed to queue: #{count}"
  end          
end
