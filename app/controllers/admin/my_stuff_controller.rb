class Admin::MyStuffController < Admin::BaseController
  respond_to :html, :json

  def index
    @editions = WholeEdition.any_of(
      {'actions.requester_id' => current_user.id},
      {'assigned_to_id' => current_user.id}
    )
  end
end
