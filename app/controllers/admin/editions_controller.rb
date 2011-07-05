class Admin::EditionsController < InheritedResources::Base
  defaults :route_prefix => 'admin'
  belongs_to :guide
 
  def update
    update! { admin_guides_path(@guide) }
  end
end
