class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include GDS::SSO::ControllerMethods
  
  # def current_user
  #   @current_user ||= User.first
  # end
end
