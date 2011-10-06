class Admin::TransactionsController < Admin::BaseController
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

  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Transaction destroyed" and return }
    else
      redirect_to admin_transaction_path(resource), :notice => 'Cannot delete a transaction that has ever been published.' and return
    end
  end

  def update
    update! do |s,f| 
      s.json { render :json => @transaction }
      f.json { render :json => @transaction.errors, :status => 406 }
    end
  end
end
