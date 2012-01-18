namespace :sync do
  desc "Broadcast all current publications states"
  task :broadcast => :environment do
    Publication.published.each do |pub|
      puts "Syncing #{pub.name}"
      Messenger.instance.published pub
    end
  end

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

  desc "Pretend that everything in publisher is published and put it on the published msg queue"
  task :publish_everything => :environment do
    count = 0
    Publication.all.each do |pub|
      Messenger.instance.published pub
      count += 1
      puts "[#{count}] #{pub.name} pushed to queue"
    end
    puts "Total records pushed to queue: #{count}"
  end

  desc "Finds panopticon IDs for publications without them"
  task :ids => :environment do
    @without_id = Publication.where(:panopticon_id.exists => false)
    puts "Found #{@without_id.count} publications without panopticon IDs"
    @without_id.each do |publication|
      print "[#{publication.id}] "
      unless publication.slug
        print "No slug found\n".colorize(:red)
        next
      end
      panopticon_resource = open(publication.panopticon_uri + '.js').read rescue ''
      artefact = JSON.parse panopticon_resource rescue ''

      if artefact
        print "Found slug `#{publication.slug}` to artefact ##{artefact['id']}".colorize(:green)
        publication.update_attribute(:panopticon_id, artefact['id'])
      else
        print "Could not find artefact for slug `#{publication.slug}`".colorize(:red)
      end
      print "\n"
    end
  end
end
