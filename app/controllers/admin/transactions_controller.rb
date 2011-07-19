class Admin::TransactionsController < InheritedResources::Base

  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'
  
  def index
    redirect_to admin_transactions_url
  end

  def show
    @transaction = resource
    @latest_edition = resource.latest_edition
  end
  
  def create
    @transaction = current_user.create_transaction(params[:transaction])
    if @transaction.save
      redirect_to admin_transaction_path(@transaction), :notice => 'Transaction successfully created' and return
    else
      render :action => 'new'
    end
  end

  def update
    update! { admin_transaction_url(@transaction, :anchor => 'metadata') }
  end
  
  def progress
    @transaction = resource
    @latest_edition = resource.latest_edition
    notes = params[:comment] || ''

    case params[:activity]
    when 'request_review'
      current_user.request_review(@latest_edition, notes)
    when 'review'
      current_user.review(@latest_edition, notes)
    when 'okay'
      current_user.okay(@latest_edition, notes)
    when 'publish'
      current_user.publish(@latest_edition, notes)
    end

    @latest_edition.save
    
    redirect_to admin_transaction_path(@transaction), :notice => 'transaction updated'
  end
end
