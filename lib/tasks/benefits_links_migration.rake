require 'benefits_links_migrator'

namespace :benefits_links do
  desc "Finds editions containing benefits anchors"
  task :report => :environment do 
    BenefitsLinksMigrator.new.report
  end
  desc "Replaces benefits specific anchors with corresponding path fragments"
  task :replace_anchors, [:user] => :environment do |t, args| 
    BenefitsLinksMigrator.new.replace_anchors(args[:user])
  end
end
