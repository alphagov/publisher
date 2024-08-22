# frozen_string_literal: true

class FilteredEditionsPresenter
  ITEMS_PER_PAGE = 20

  def initialize(states_filter: [], assigned_to_filter: nil, format_filter: nil, title_filter: nil)
    @states_filter = states_filter || []
    @assigned_to_filter = assigned_to_filter
    @format_filter = format_filter
    @title_filter = title_filter
  end

  def available_users
    User.enabled.alphabetized
  end

  def editions
    result = editions_by_format
    result = apply_states_filter(result)
    result = apply_assigned_to_filter(result)
    result = apply_title_filter(result)
    result = result.where.not(_type: "PopularLinksEdition")
    # Sets a temporary limit of one page and twenty items
    # Pagination to follow
    result.page(1).per(ITEMS_PER_PAGE)
  end

private

  def editions_by_format
    return Edition.all unless format_filter && format_filter != "all"

    Edition.where(_type: "#{format_filter.camelcase}Edition")
  end

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

  def apply_title_filter(editions)
    return editions if title_filter.blank?

    editions.title_contains(title_filter)
  end

  attr_reader :states_filter, :assigned_to_filter, :format_filter, :title_filter
end
