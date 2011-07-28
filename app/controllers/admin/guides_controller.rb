class Admin::GuidesController < InheritedResources::Base

  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'
  
  respond_to :html, :json
  
  def index
    @drafts = Publication.in_draft
    @published = Publication.published
    @archive = Publication.archive
    @review_requested = Publication.review_requested
  end

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
    current_user = self.current_user
    notes = params[:comment] || ''
    resource.latest_edition.progress(params[:activity],current_user,notes)    
    redirect_to admin_guide_path(resource), :notice => 'Guide updated'
  end
end
