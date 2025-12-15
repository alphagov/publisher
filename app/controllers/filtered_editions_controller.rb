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

    @welsh_editions, @english_editions = presenter.editions.partition { |edition| edition.artefact.welsh? }
  end
end
