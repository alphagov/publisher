namespace :states do
  
  desc "Migrate states from multiple flags to a single state field"
  task :migrate => :environment do
                                                              
    @state_migrations = {                       
      'assigned' => 'lined_up',      
      'created' => 'lined_up',      
      'work_started' => 'draft',
      'review_requested' => 'in_review',     
      'reviewed' => 'amends_needed',
      'okayed' => 'ready',                 
      'fact_check_requested' => 'fact_check',
      'fact_check_received' => 'fact_check_received',
      'published' => 'published',
    }
      
    Publication.all.each do |p|
      p.editions.each do |e|       
         state = @state_migrations[e.actions.where(:request_type.ne => 'note').last.request_type]
        if e.update_attribute(:state, state)
          puts "Updated \"#{p.name}\" with state \"#{state}\""
        else
          puts "Could not update \"#{p.name}\""
        end
      end
    end
      
  end
  
end