namespace :states do
  
  desc "Migrate states to state machine and publishings to edition actions"
  task :migrate => :environment do
                                                              
    @state_migrations = {                       
      'assigned' => 'lined_up',      
      'created' => 'lined_up',  
      'new_version' => 'draft',    
      'work_started' => 'draft',
      'review_requested' => 'in_review',     
      'reviewed' => 'amends_needed', 
      'request_amendments' => 'amends_needed',
      'okayed' => 'ready',
      'approve_review' => 'ready',                 
      'fact_check_requested' => 'fact_check',
      'fact_check_received' => 'fact_check_received',
      'published' => 'published',
    }
      
    Publication.all.each do |p|
      p.editions.each do |e|                 
        last_action = e.actions.where(:request_type.ne => 'note').last.request_type
        state = @state_migrations[last_action]
        if state and state.nil?
          puts "Error: no match for last action \"#{last_action}\""
        elsif e.update_attribute(:state, state)
          puts "Updated \"#{p.name}\" (v#{e.version_number}) from action \"#{last_action}\" to state \"#{state}\""
        else
          puts "Could not update \"#{p.name}\""
        end
      end  
      
      p.publishings.each do |publishing|                                                                   
        puts "Finding version #{publishing.version_number}..."
        edition = p.editions.where(version_number: publishing.version_number).first                             
        puts "Found edition #{edition.id}. Edition has #{edition.actions.count} actions."
        action = edition.actions.where(request_type: 'published').first
        puts action.inspect
        if action and action.update_attributes(notes: publishing.change_notes)
          puts "Updated notes with \"#{publishing.change_notes}\""
        else
          puts "Could not update notes."
        end
      end
    end    
  end  
  
end