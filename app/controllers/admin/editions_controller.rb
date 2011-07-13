class Admin::EditionsController < InheritedResources::Base
  #before_filter :authenticate_user!
  
  defaults :route_prefix => 'admin'
  belongs_to :guide
 
  def create
    guide = Guide.find(params[:guide_id])
    new_edition = guide.build_edition(guide.latest_edition.title)
    if new_edition.save
      redirect_to [:admin, guide], :notice => 'New edition created'
    else
      redirect_to [:admin, guide], :notice => 'Failed to create new edition'
    end
  end

  def update
    update! { admin_guide_path(@guide) }
  end
end
