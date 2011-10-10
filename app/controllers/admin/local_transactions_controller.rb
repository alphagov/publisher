class Admin::LocalTransactionsController < Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_local_transaction_path(r)
  end

  def create_new
    current_user.create_local_transaction(params[:local_transaction])
  end
end
