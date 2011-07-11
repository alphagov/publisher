class Admin::GuidesController < InheritedResources::Base

  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'
  
  def index
    @drafts = Guide.in_draft
    @published = Guide.published
    @archive = Guide.archive
    @review_requested = Guide.review_requested
  end

  def show
    @guide = resource
    @latest_edition = resource.latest_edition
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
    update! { admin_guide_url(@guide, :anchor => 'metadata') }
  end
  
  def progress
    @guide = resource
    @latest_edition = resource.latest_edition
    notes = ''

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
    
    redirect_to admin_guide_path(@guide), :notice => 'Guide updated'
  end
end
