class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include GDS::SSO::ControllerMethods

  def self.local_ip_addresses
    @local_ip_addresses ||= Socket.ip_address_list.map(&:ip_address)
  end

protected

  def local_request?
    self.class.local_ip_addresses.include?(request.ip)
  end
end
