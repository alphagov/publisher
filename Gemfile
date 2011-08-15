source 'http://rubygems.org'

gem 'rails', '~> 3.0.7'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "mongoid", "~> 2.0"
gem "bson_ext", "~> 1.3"
gem 'sinatra'
gem 'erubis'

gem 'inherited_resources'
gem 'formtastic'
gem 'has_scope'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', :path => '../gds-sso'
else
  gem 'gds-sso', :git => 'git@github.com:alphagov/gds-sso.git'
end

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', :git => 'git@github.com:alphagov/slimmer.git'
end

if ENV['GEO_DEV']
  gem 'rack-geo', :path => '../rack-geo'
  gem 'geogov', :path => '../geogov'
else
  gem 'rack-geo', :git => 'git@github.com:alphagov/rack-geo.git'
end

gem 'cdn_helpers', :git => 'git@github.com:alphagov/cdn_helpers.git', :tag => 'v0.8.3'

gem 'govspeak', :git => 'git@github.com:alphagov/govspeak.git'

gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'

group :development, :test do
  gem 'passenger'
  gem 'fabrication'
  gem "timecop"
  gem 'capybara', '~> 1.0.0'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'mocha', :require => false
end
