class Admin::ProgrammesController <  Admin::BaseController
  respond_to :html, :json

  def show
    @programme = resource
    @latest_edition = resource.latest_edition
  end

  def create
    @programme = current_user.create_programme(params[:programme])
    if @programme.save
      redirect_to admin_programme_path(@programme), :notice => 'Programme successfully created' and return
    else
      render :action => 'new'
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Programme destroyed" and return }
    else
      redirect_to admin_programme_path(resource), :notice => 'Cannot delete a programme that has ever been published.' and return
    end
  end

  def update
    update! do |s,f|
      s.json { render :json => @programme }
      f.json { render :json => @programme.errors, :status => 406 }
    end
  end
end
