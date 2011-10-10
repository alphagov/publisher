class Admin::TransactionsController < Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_transaction_path(r)
  end

  def create_new
    current_user.create_transaction(params[:transaction])
  end
end
