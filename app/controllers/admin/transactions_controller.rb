class Admin::TransactionsController < Admin::PublicationSubclassController

private
  def identifier
    :transaction
  end
end
