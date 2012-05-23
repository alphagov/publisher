class Admin::MyStuffController < Admin::BaseController
  respond_to :html, :json

  def index
    @editions = WholeEdition.where(
      'actions.requester_id' => BSON::ObjectId('4e5e3481e2ba805990000020'))
  end
end
