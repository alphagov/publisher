class Admin::BaseController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  def index
    redirect_to admin_root_url
  end
end
