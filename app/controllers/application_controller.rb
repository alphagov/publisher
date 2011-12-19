class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include GDS::SSO::ControllerMethods

protected
  def allow_preview?
    request.local?
  end
end
