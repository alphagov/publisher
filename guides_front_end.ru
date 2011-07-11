# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'guides_front_end'
use  Slimmer::App, :template_host => "#{File.expand_path('../public/templates', __FILE__)}"
run GuidesFrontEnd
