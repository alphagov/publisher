class UserSearchController < ApplicationController
  respond_to :html

  include ColumnSortable

  def index
    @user_filter = params[:user_filter] || current_user.uid
    @user = params[:user_filter] ? User.where(:uid => @user_filter).first : current_user
    raise ActionController::RoutingError.new('Not Found') unless @user

    # Warning: this works for all our current users, but is likely to break in
    # future. We should update our user model to have the concept of a forename
    @user_forename = @user.name.split()[0]

    if params[:string_filter].present?
      clean_string_filter = params[:string_filter]
                                .strip
                                .gsub(/\s+/, ' ')
      editions = filtered_editions.user_search(@user, clean_string_filter)
    else
      editions = filtered_editions.for_user(@user)
    end

    editions = editions.excludes(state: 'archived')
    editions = editions.order_by([sort_column, sort_direction])

    # Need separate assignments here because Kaminari won't preserve pagination
    # info across a map, and we don't want to load every edition and paginate
    # the resulting array
    @page_info = editions.page(params[:page]).per(20)
    @editions = @page_info.map { |e| UserSearchEditionDecorator.new e, @user }
  end

private

  def format_filter
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].include?(params[:format_filter]) ? params[:format_filter] : 'edition'
  end

  def filtered_editions
    return Edition if format_filter == 'edition'
    Edition.where(_type: format_filter.camelcase + 'Edition')
  end
end
