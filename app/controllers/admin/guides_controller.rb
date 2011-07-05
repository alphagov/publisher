class Admin::GuidesController < InheritedResources::Base
  defaults :route_prefix => 'admin'
  
  def show
    @guide = resource
    @latest_edition = resource.latest_edition
  end
end
