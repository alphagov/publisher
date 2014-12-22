class DowntimesController < ApplicationController

  def index
    @transactions = TransactionEdition.published
  end

end
