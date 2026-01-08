class FilteredEditionsController < ApplicationController
  layout "design_system"

  def my_content
    @presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: Edition.state_names.excluding(:archived, :published),
      assigned_to_filter: current_user.id,
    )
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
