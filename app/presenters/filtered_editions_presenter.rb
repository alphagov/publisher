# frozen_string_literal: true

class FilteredEditionsPresenter
  include BaseHelper

  ITEMS_PER_PAGE = 20

  attr_reader :search_text

  def initialize(user, states_filter: [], assigned_to_filter: nil, content_type_filter: nil, search_text: nil, paginate: false, page: nil)
    @user = user
    @states_filter = states_filter || []
    @assigned_to_filter = assigned_to_filter
    @content_type_filter = content_type_filter
    @search_text = search_text
    @paginate = paginate
    @page = page
  end

  def content_type_options
    options = [{ text: "All types", value: "", selected: @content_type_filter.blank? }]

    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].each do |format_name|
      options << { text: format_name.humanize, value: format_name, selected: @content_type_filter == format_name }
    end

    options
  end

  def edition_states
    states = [{ text: "All active statuses", value: "" }]
    state_names.map do |scope, status_label|
      states << if @states_filter.include? scope.to_s
                  { text: status_label, value: scope, selected: "true" }
                else
                  { text: status_label, value: scope }
                end
    end

    states
  end

  def assignees
    users = [{ text: "All assignees", value: "" }]
    users << create_assignee_list_item(@user)

    available_users.map do |user|
      next if user == @user

      users << create_assignee_list_item(user)
    end
    users
  end

  def editions
    @editions ||= query_editions
  end

private

  def create_assignee_list_item(user)
    user_name = if user == @user
                  "#{user.name} (You)"
                else
                  user.name
                end
    if user.id.to_s == @assigned_to_filter
      { text: user_name, value: user.id, selected: "true" }
    else
      { text: user_name, value: user.id }
    end
  end

  def query_editions
    result = editions_by_content_type
    result = apply_states_filter(result)
    result = apply_assigned_to_filter(result)
    result = apply_search_text(result)
    result = result.accessible_to(user)
    result = result.order(updated_at: :desc)
    apply_pagination(result)
  end

  def available_users
    User.enabled.alphabetized
  end

  def state_names
    {
      draft: "Draft",
      in_review: humanize_state("in_review"),
      amends_needed: "Amends needed",
      fact_check: "Out for fact check",
      fact_check_received: "Fact check received",
      ready: "Ready",
      scheduled_for_publishing: "Scheduled",
      published: "Published",
      archived: "Archived",
    }
  end

  def editions_by_content_type
    return Edition.where.not(editionable_type: "PopularLinksEdition") if @content_type_filter.blank?

    Edition.where(editionable_type: "#{@content_type_filter.camelcase}Edition")
  end

  def apply_states_filter(edition)
    return edition.where.not(state: "archived") if states_filter.empty?

    edition.where(state: states_filter)
  end

  def apply_assigned_to_filter(editions)
    return editions unless assigned_to_filter

    if assigned_to_filter == "nobody"
      editions = editions.assigned_to(nil)
    else
      begin
        assigned_user = User.find(assigned_to_filter)
        editions = editions.assigned_to(assigned_user) if assigned_user
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn "An attempt was made to filter by an unknown user ID: '#{assigned_to_filter}'"
      end
    end
    editions
  end

  def apply_search_text(editions)
    return editions if search_text.blank?

    editions.search_title_and_slug(search_text)
  end

  def apply_pagination(editions)
    return editions unless @paginate

    editions.page(@page).per(ITEMS_PER_PAGE)
  end

  attr_reader :user, :states_filter, :assigned_to_filter, :content_type_filter, :page
end
