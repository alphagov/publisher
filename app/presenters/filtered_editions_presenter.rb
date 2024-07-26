# frozen_string_literal: true

class FilteredEditionsPresenter
  def initialize(states_filter)
    @states_filter = states_filter || []
  end

  def editions
    result = Edition.all
    result = result.in_states(states_filter) unless states_filter.empty?
    result
  end

private

  attr_reader :states_filter
end
