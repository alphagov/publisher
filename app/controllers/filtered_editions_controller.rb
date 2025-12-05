class FilteredEditionsController < ApplicationController
  layout "design_system"

  def my_content
    @presenter = FilteredEditionsPresenter.new(
      current_user,
      states_filter: Edition.state_names.excluding(:archived, :published),
      assigned_to_filter: current_user.id,
    )
  end
end
