desc "Update the dashboard in Publisher with aggregated state counts"
task :update_publisher_dashboard => :environment do
                   
  def initialize_states
    @hash = { }
    Edition.state_machine.states.map(&:name).each do |state|
      @hash[state] = 0
    end               
    @hash
  end                                                      
  
  def filter_empty_values(attribute_value)
    (attribute_value.nil? || attribute_value.empty?) ? "**UNASSIGNED**" : attribute_value
  end          
  
  TOTAL_ROW = '**TOTAL**'
                
  @output = {}
  {'Format' => 'format_type','Section' => 'section','Writing Department' => 'department'}.each do |view, attribute|
                
    @index = { }        
    
    @index[TOTAL_ROW] = initialize_states
                
    Publication.all.each do |publication|
      latest_edition = publication.latest_edition
      state = latest_edition.state_name
      
      attribute_value = publication.send(attribute)
      attribute_value = filter_empty_values(attribute_value)
      if @index[attribute_value].nil?
        @index[attribute_value] = initialize_states
      end
      @index[attribute_value][state] += 1     
      
      @index[TOTAL_ROW][state] += 1
    end                
    
    @output[view.to_sym] = @index
    
  end                            
  
  puts @output.inspect
  
end