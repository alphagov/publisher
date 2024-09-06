# frozen_string_literal: true

class FilteredEditionsPresenter
  ITEMS_PER_PAGE = 20

  def initialize(states_filter: [], assigned_to_filter: nil, content_type_filter: nil, title_filter: nil, page: nil)
    @states_filter = states_filter || []
    @assigned_to_filter = assigned_to_filter
    @content_type_filter = content_type_filter
    @title_filter = title_filter
    @page = page
  end

  def title
    @title_filter
  end

  def content_types
    types = []

    content_type_filter_selection_options.map do |content_type|
      types << if content_type[1] == @content_type_filter
                 { text: content_type[0], value: content_type[1], selected: "true" }
               else
                 { text: content_type[0], value: content_type[1] }
               end
    end

    types
  end

  def edition_states
    states = []

    state_names.map do |scope, status_label|
      states << if @states_filter.include? scope.to_s
                  { label: status_label, value: scope, checked: "true" }
                else
                  { label: status_label, value: scope }
                end
    end

    states
  end

  def available_users
    User.enabled.alphabetized
  end

  def assignees
    users = [{ text: "All assignees", value: "" }]

    available_users.map do |user|
      users << if user.id.to_s == @assigned_to_filter
                 { text: user.name, value: user.id, selected: "true" }
               else
                 { text: user.name, value: user.id }
               end
    end

    users
  end

  def editions
    result = editions_by_content_type
    result = apply_states_filter(result)
    result = apply_assigned_to_filter(result)
    result = apply_title_filter(result)
    result = result.where.not(_type: "PopularLinksEdition")
    result.order_by(%w[updated_at desc]).page(@page).per(ITEMS_PER_PAGE)
  end

private

  def state_names
    {
      draft: "Drafts",
      in_review: "In review",
      amends_needed: "Amends needed",
      fact_check: "Out for fact check",
      fact_check_received: "Fact check received",
      ready: "Ready",
      scheduled_for_publishing: "Scheduled",
      published: "Published",
      archived: "Archived",
    }
  end

  def content_type_filter_selection_options
    [%w[All all]] +
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].map do |format_name|
        displayed_format_name = format_name.humanize
        displayed_format_name += " (Retired)" if Artefact::RETIRED_FORMATS.include?(format_name)
        [displayed_format_name, format_name]
      end
  end

  def editions_by_content_type
    return Edition.all unless content_type_filter && content_type_filter != "all"

    Edition.where(_type: "#{content_type_filter.camelcase}Edition")
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

  attr_reader :states_filter, :assigned_to_filter, :content_type_filter, :title_filter, :page
end
