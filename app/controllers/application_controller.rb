class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include GDS::SSO::ControllerMethods
end
