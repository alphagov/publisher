class Admin::LocalTransactionsController < Admin::BaseController
  def show
    @local_transaction = resource
    @latest_edition = resource.latest_edition
  end
  
  def create
    @local_transaction = current_user.create_local_transaction(params[:local_transaction])
    if @local_transaction.save
      redirect_to admin_local_transaction_path(@local_transaction), :notice => 'Local Transaction successfully created' and return
    else
      render :action => 'new'
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Local Transaction destroyed" and return }
    else
      redirect_to admin_local_transaction_path(resource), :notice => 'Cannot delete a Local Transaction that has ever been published.' and return
    end
  end

  def update
    update! do |s,f| 
      s.json { render :json => @local_transaction }
      f.json { render :json => @local_transaction.errors, :status => 406 }
    end
  end
  
  def progress
    current_user = self.current_user
    notes = params[:comment] || ''
    resource.latest_edition.progress(params[:activity],current_user,notes)    
    redirect_to admin_local_transaction_path(resource), :notice => 'Local Transaction updated'
  end
end
