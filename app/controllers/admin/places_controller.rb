class Admin::PlacesController < Admin::BaseController
  def show
    @place = resource
    @latest_edition = resource.latest_edition
  end
  
  def create
    @place = current_user.create_place(params[:place])
    if @place.save
      redirect_to admin_place_path(@place), :notice => 'Place successfully created' and return
    else
      render :action => 'new'
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Place destroyed" and return }
    else
      redirect_to admin_place_path(resource), :notice => 'Cannot delete a place that has ever been published.' and return
    end
  end

  def update
    update! do |s,f| 
      s.json { render :json => @place }
      f.json { render :json => @place.errors, :status => 406 }
    end
  end
  
  def progress
    resource.latest_edition.progress(params[:activity], current_user)
    redirect_to admin_place_path(resource), :notice => 'Place updated'
  end
end
