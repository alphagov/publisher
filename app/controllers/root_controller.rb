# frozen_string_literal: true

class RootController < ApplicationController
  layout "design_system"

  PERMITTED_FILTER_STATES = %w[
    draft
    amends_needed
    in_review
    fact_check
    fact_check_received
    ready
    scheduled_for_publishing
    published
    archived
  ].freeze

  def index
    filter_params_hash = filter_params.to_h
    states_filter_params = filter_params_hash[:states_filter]
    sanitised_states_filter_params = states_filter_params&.select { |fp| PERMITTED_FILTER_STATES.include?(fp) }
    session[:assignee_filter] = assignee_filter
    content_type_filter = filter_params_hash[:content_type_filter]
    search_text = filter_params_hash[:search_text]
    @presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: sanitised_states_filter_params,
      assigned_to_filter: assignee_filter,
      content_type_filter:,
      search_text:,
      page: filter_params_hash[:page],
    )
  end

private

  def assignee_filter
    filter_params_hash = filter_params.to_h
    if filter_params_hash[:assignee_filter]
      filter_params_hash[:assignee_filter]
    elsif session[:assignee_filter]
      session[:assignee_filter]
    else
      current_user.id.to_s
    end
  end

  def filter_params
    params.permit(:page, :assignee_filter, :content_type_filter, :search_text, states_filter: [])
  end
end
