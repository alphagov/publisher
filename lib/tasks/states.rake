namespace :states do
  
  desc "Migrate states to state machine and publishings to edition actions"
  task :migrate_states => :environment do
                                                              
    @state_migrations = {                        
      'created' => 'lined_up',  
      'new_version' => 'draft',    
      'work_started' => 'draft',
      'start_work' => 'draft',
      'request_review' => 'in_review',
      'review_requested' => 'in_review',     
      'reviewed' => 'amends_needed', 
      'request_amendments' => 'amends_needed',
      'okayed' => 'ready',
      'approve_review' => 'ready',                 
      'fact_check_requested' => 'fact_check',
      'send_fact_check' => 'fact_check',
      'fact_check_received' => 'fact_check_received',
      'receive_fact_check' => 'fact_check_received',
      'published' => 'published',      
      'publish' => 'published',
    }
      
    Publication.all.each do |p|
      p.editions.each do |e|                 
        last_action = e.actions.where(:request_type.nin => ['note','assigned','assign']).last.request_type rescue '' 
        #unless e.state.nil?
        #  puts "State \"#{e.state}\" already present for \"#{p.name}\".".colorize(:cyan)
        #  next
        #end
        
        state = @state_migrations[last_action]
        if !state or state.nil?
          puts "Error: no match for last action \"#{last_action}\"".colorize(:red)
        elsif e.update_attribute(:state, state)
          puts "Updated \"#{p.name}\" (v#{e.version_number}) from action \"#{last_action}\" to state \"#{state}\"".colorize(:green)
        else
          puts "Could not update \"#{p.name}\", existing state \"#{state}\"".colorize(:red)
        end
      end  
      
      p.publishings.each do |publishing|                                                                   
        puts "Finding version #{publishing.version_number}..."
        edition = p.editions.where(version_number: publishing.version_number).first                             
        action = edition.actions.where(request_type: 'published').first
                                                                                                                       
        action_type = action.request_type rescue nil
        unless action_type.nil?
          puts "Found edition #{edition.id}. Edition has #{edition.actions.count} actions. Published action found: \"#{action_type}\""
          if action and action.update_attributes(notes: publishing.change_notes)
            puts "Migrated publish notes with \"#{publishing.change_notes}\"".colorize(:green)
          else
            puts "Could not update notes.".colorize(:red)
          end
        else
          puts "No published action found."
        end
      end
    end    
  end
  
  task :migrate_assigned => :environment do
                                                              
    Publication.all.each do |p|
      p.editions.each do |e|                 
        e.actions.where('request_type' => 'assigned').update_all('request_type' => 'assign')
        puts "Updated edition #{e.id}"
      end  

    end    

  end  
  
end