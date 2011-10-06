class Admin::GuidesController <  Admin::BaseController
  respond_to :html, :json

  def show
    @guide = resource
    @latest_edition = resource.latest_edition
  end
  
  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Guide destroyed" and return }
    else
      redirect_to admin_guide_path(resource), :notice => 'Cannot delete a guide that has ever been published.' and return
    end
  end
  
  def create
    @guide = current_user.create_guide(params[:guide])
    if @guide.save
      redirect_to admin_guide_path(@guide), :notice => 'Guide successfully created' and return
    else
      render :action => 'new'
    end
  end
  
  def update
    update! do |s,f| 
      s.json { render :json => @guide }
      f.json { render :json => @guide.errors, :status => 406 }
    end
  end
  
  def progress
    resource.latest_edition.progress(params[:activity], current_user)
    redirect_to admin_guide_path(resource), :notice => 'Guide updated'
  end
end
