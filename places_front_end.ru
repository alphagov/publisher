# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'places_front_end/app'

app_path = File.dirname(__FILE__)

case ENV['RACK_ENV']
  when ('development' or 'test')
    static_dir = app_path + "/public"
  when 'production'
    static_dir = "/data/vhost/static.alpha.gov.uk/current/public"
  else
    static_dir = "/data/vhost/static.#{ENV['RACK_ENV']}.alphagov.co.uk/current/public"
end


use Slimmer::App, :template_host => static_dir + "/templates"
run PlacesFrontEnd::App
