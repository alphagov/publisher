desc "Update the dashboard in Publisher with aggregated state counts"
task :update_publisher_dashboard => :environment do

  def initialize_states
    @hash = {:count => 0}
      ['lined_up', 'draft', 'amends_needed', 'in_review', 'fact_check', 'fact_check_received', 'ready', 'published', 'archived'].each do |state|
      @hash[state] = 0
    end

    @hash
  end

  def filter_empty_values(attribute_value)
    (attribute_value.nil? || attribute_value.empty?) ? OverviewDashboard::UNASSIGNED_KEY : attribute_value
  end

  @output = {}

  {'Format' => '_type', 'Section' => 'section', 'Writing Department' => 'department'}.each do |view, attribute|
    @index = {}
    @index[OverviewDashboard::TOTAL_KEY] = initialize_states

    WholeEdition.all.each do |edition|
      if edition.latest_edition?
        state = edition.state
        attribute_value = filter_empty_values(edition.send(attribute))
        attribute_value.sub!("Edition","") if attribute == "_type"

        if @index[attribute_value].nil?
          @index[attribute_value] = initialize_states
        end

        @index[attribute_value][state] += 1
        @index[attribute_value][:count] += 1
        @index[OverviewDashboard::TOTAL_KEY][state] += 1
        @index[OverviewDashboard::TOTAL_KEY][:count] += 1
      end
    end

    @output[view.to_sym] = @index
  end

  OverviewDashboard.delete_all

  @output.each do |dashboard_type, group_data|
    group_data.each do |result_group, group_data|
      puts "#{dashboard_type} #{result_group} #{group_data.inspect}"
      OverviewDashboard.create(group_data.merge(:dashboard_type => dashboard_type, :result_group => result_group))
    end
  end

  puts "Done"
end

