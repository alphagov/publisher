class Admin::UserSearchController < Admin::BaseController
  respond_to :html

  def index
    @user_filter = params[:user_filter] || current_user.uid
    user = params[:user_filter] ? User.find_by_uid(@user_filter) : current_user

    @editions = WholeEdition.any_of(
      {'actions.requester_id' => user.id}, {'assigned_to_id' => user.id}
    )
  end
end
