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
    assignee_filter = filter_params_hash[:assignee_filter]
    format_filter = filter_params_hash[:format_filter]
    title_filter = filter_params_hash[:title_filter]
    @presenter = FilteredEditionsPresenter.new(
      states_filter: sanitised_states_filter_params,
      assigned_to_filter: assignee_filter,
      format_filter:,
      title_filter:,
      page: filter_params_hash[:page],
    )
  end

private

  def filter_params
    params.permit(:page, :assignee_filter, :format_filter, :title_filter, states_filter: [])
  end
end
