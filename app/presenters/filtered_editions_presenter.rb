# frozen_string_literal: true

class FilteredEditionsPresenter
  def initialize(states_filter, assigned_to_filter)
    @states_filter = states_filter || []
    @assigned_to_filter = assigned_to_filter
  end

  def available_users
    User.enabled.alphabetized
  end

  def editions
    result = Edition.all
    result = apply_states_filter(result)
    apply_assigned_to_filter(result)
  end

private

  def apply_states_filter(editions)
    return editions if states_filter.empty?

    editions.in_states(states_filter)
  end

  def apply_assigned_to_filter(editions)
    return editions unless assigned_to_filter

    if assigned_to_filter == "nobody"
      editions = editions.assigned_to(nil)
    else
      begin
        assigned_user = User.find(assigned_to_filter)
        editions = editions.assigned_to(assigned_user) if assigned_user
      rescue Mongoid::Errors::DocumentNotFound
        Rails.logger.warn "An attempt was made to filter by an unknown user ID: '#{assigned_to_filter}'"
      end
    end
    editions
  end

  attr_reader :states_filter, :assigned_to_filter
end
