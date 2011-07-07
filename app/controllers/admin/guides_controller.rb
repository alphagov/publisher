class Admin::GuidesController < InheritedResources::Base
  #before_filter :authenticate_user!
  
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
end
