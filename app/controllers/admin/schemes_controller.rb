class Admin::SchemesController <  Admin::BaseController
  respond_to :html, :json

  def show
    @scheme = resource
    @latest_edition = resource.latest_edition
  end
  
  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Scheme destroyed" and return }
    else
      redirect_to admin_scheme_path(resource), :notice => 'Cannot delete a guide that has ever been published.' and return
    end
  end
  
  def create
    @scheme = current_user.create_scheme(params[:scheme])
    if @scheme.save
      redirect_to admin_scheme_path(@scheme), :notice => 'Scheme successfully created' and return
    else
      render :action => 'new'
    end
  end
  
  def update
    update! do |s,f| 
      s.json { render :json => @scheme }
      f.json { render :json => @scheme.errors, :status => 406 }
    end
  end
  
  def progress
    current_user = self.current_user
    notes = params[:comment] || ''
    resource.latest_edition.progress(params[:activity],current_user,notes)    
    redirect_to admin_scheme_path(resource), :notice => 'Scheme updated'
  end
end

