class FilteredEditionsController < ApplicationController
  layout "design_system"

  def my_content
    @presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: Edition.state_names.excluding(:archived, :published),
      assigned_to_filter: current_user.id,
    )
  end

  def fact_check
    presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: %i[fact_check_received fact_check],
    )

    @fact_check_received_editions = presenter.editions
                                             .select { it.state == "fact_check_received" }
                                             .sort_by { it.most_recent_action { it.request_type == "receive_fact_check" }.created_at }
                                             .reverse!

    @fact_check_sent_editions = presenter.editions
                                         .select { it.state == "fact_check" }
                                         .sort_by(&:last_fact_checked_at)
                                         .reverse!
  end

  def two_eye_queue
    presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: %i[in_review],
    )

    @welsh_editions, @english_editions = presenter.editions.sort_by(&:review_requested_at).partition { |edition| edition.artefact.welsh? }
  end

  def find_content
    filter_params_hash = filter_params.to_h
    @presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: Edition.state_names.excluding(:archived),
      paginate: true,
      page: filter_params_hash[:page],
    )
  end

private

  def filter_params
    params.permit(:page)
  end
end
