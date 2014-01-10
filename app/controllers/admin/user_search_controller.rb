class Admin::UserSearchController < Admin::BaseController
  respond_to :html

  include Admin::ColumnSortable

  def index
    @user_filter = params[:user_filter] || current_user.uid
    @user = params[:user_filter] ? User.find_by_uid(@user_filter) : current_user
    raise ActionController::RoutingError.new('Not Found') unless @user

    # Warning: this works for all our current users, but is likely to break in
    # future. We should update our user model to have the concept of a forename
    @user_forename = @user.name.split()[0]

    if params[:string_filter].present?
      clean_string_filter = params[:string_filter]
                                .strip
                                .gsub(/\s+/, ' ')
      editions = Edition.user_search(@user, clean_string_filter)
    else
      editions = Edition.for_user(@user)
    end

    editions = editions.excludes(state: 'archived')
    editions = editions.order_by([sort_column, sort_direction])

    # Need separate assignments here because Kaminari won't preserve pagination
    # info across a map, and we don't want to load every edition and paginate
    # the resulting array
    @page_info = editions.page(params[:page]).per(20)
    @editions = @page_info.map { |e| UserSearchEditionDecorator.new e, @user }
  end
end
