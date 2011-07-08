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
  
  def update
    update! { admin_guide_url(@guide, :anchor => 'metadata') }
  end
  
  def progress
    @guide = resource
    @latest_edition = resource.latest_edition
    
    case params[:activity]
    when 'request review'
      current_user.request_review(@latest_edition)
    when 'review'
      current_user.review(@latest_edition)
    when 'okay'
      current_user.okay(@latest_edition)
    when 'publish'
      current_user.publish(@latest_edition)
    end
    
    redirect_to admin_guide_path(@guide), :notice => 'Guide updated'
  end
end
