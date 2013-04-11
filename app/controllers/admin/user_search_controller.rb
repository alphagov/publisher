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

    # Including recipient_id on actions will include anything that has been
    # assigned to the user we're looking at, but include the check anyway to
    # account for manual assignments
    editions = Edition.any_of(
      {'assigned_to_id' => @user.id},
      {'actions.requester_id' => @user.id},
      {'actions.recipient_id' => @user.id}
    ).excludes(state: 'archived').order_by([sort_column, sort_direction])

    unless params[:string_filter].blank?
      clean_string_filter = params[:string_filter]
                                .strip
                                .gsub(/\s+/, ' ')
      editions = editions.internal_search(clean_string_filter)
    end

    # Need separate assignments here because Kaminari won't preserve pagination
    # info across a map, and we don't want to load every edition and paginate
    # the resulting array
    @page_info = editions.page(params[:page]).per(20)
    @editions = @page_info.map { |e| UserSearchEditionDecorator.new e, @user }
  end
end
