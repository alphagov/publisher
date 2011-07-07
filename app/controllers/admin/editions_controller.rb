class Admin::EditionsController < InheritedResources::Base
  #before_filter :authenticate_user!
  
  defaults :route_prefix => 'admin'
  belongs_to :guide
 
  def update
    update! { admin_guide_path(@guide) }
  end
end
