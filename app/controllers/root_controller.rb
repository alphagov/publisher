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
    states_filter_params = filter_params.to_h[:states_filter]
    sanitised_states_filter_params = states_filter_params&.select { |fp| PERMITTED_FILTER_STATES.include?(fp) }
    @presenter = FilteredEditionsPresenter.new(sanitised_states_filter_params, nil)
  end

private

  def filter_params
    params.permit(states_filter: [])
  end
end
