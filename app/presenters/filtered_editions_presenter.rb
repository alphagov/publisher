# frozen_string_literal: true

class FilteredEditionsPresenter
  include BaseHelper

  ITEMS_PER_PAGE = 20

  attr_reader :search_text

  def initialize(user, states_filter: [], assigned_to_filter: nil, content_type_filter: nil, search_text: nil, paginate: false, page: nil)
    @user = user
    @states_filter = states_filter
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

  def state_options
    options = [{ text: "Active statuses", value: "", selected: @states_filter.blank? }]

    state_names.each do |state, label|
      options << { text: label, value: state, selected: @states_filter.first == state.to_s }
    end

    options
  end

  def assignee_options
    options = [{ text: "All assignees", value: "", selected: @assigned_to_filter.blank? }]
    options << { text: "#{@user.name} (You)", value: @user.id, selected: @assigned_to_filter == @user.id.to_s }

    User.enabled.excluding(@user).alphabetized.each do |assignee|
      options << { text: assignee.name, value: assignee.id, selected: @assigned_to_filter == assignee.id.to_s }
    end

    options
  end

  def editions
    @editions ||= query_editions
  end

private

  def query_editions
    result = editions_by_content_type
    result = apply_states_filter(result)
    result = apply_assigned_to_filter(result)
    result = apply_search_text(result)
    result = result.accessible_to(@user)
    result = result.order(updated_at: :desc)
    apply_pagination(result)
  end

  def state_names
    {
      draft: "Draft",
      in_review: humanize_state("in_review"),
      amends_needed: "Amends needed",
      fact_check: humanize_state("out_for_fact_check"),
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

  def apply_states_filter(editions)
    return editions.where.not(state: "archived") if @states_filter.empty?

    editions.where(state: @states_filter)
  end

  def apply_assigned_to_filter(editions)
    return editions if @assigned_to_filter.blank?

    begin
      assigned_user = User.find(@assigned_to_filter)
      editions = editions.assigned_to(assigned_user) if assigned_user
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "An attempt was made to filter by an unknown user ID: '#{@assigned_to_filter}'"
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
end
