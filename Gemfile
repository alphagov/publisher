source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

# GDS specific gems
gem 'gds-rails-config', :git => 'git@github.com:alphagov/gds-rails-config.git'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', :path => '../gds-sso'
else
  gem 'gds-sso', :git => 'git@github.com:alphagov/gds-sso.git'
end

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', '~> 1.1.17'
end

if ENV['CDN_DEV']
  gem 'cdn_helpers', :path => '../cdn_helpers'
else
  gem 'cdn_helpers', '0.9'
end

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', :path => '../govspeak'
else
  gem 'govspeak', '0.8.4'
end

if ENV['MARPLES_DEV']
  gem 'marples', :path => '../marples'
else
  gem 'marples', '~> 1'
end

gem 'rummageable', :git => 'git@github.com:alphagov/rummageable.git'
gem 'daemonette', :git => 'git@github.com:alphagov/daemonette.git'
gem 'pethau', '0.0.3'

# And the generic gems...

gem 'rails', '3.1.3'
gem 'aws-ses', :require => 'aws/ses'

gem "mongoid", "~> 2.3"
gem "mongo", "1.5.2"
gem "bson_ext", "1.5.2"
gem "bson", "1.5.2"
gem 'erubis'
gem 'null_logger'
gem 'rest-client'
gem "colorize", "~> 0.5.8"
gem 'inherited_resources'
gem 'formtastic', '~> 2.0.0'
gem 'has_scope'
gem 'stomp', '1.1.9'
gem 'null_logger'
gem 'state_machine'

gem 'lockfile'
gem 'whenever'

group :development do
  gem 'passenger'
  if ENV['RUBY_DEBUG']
    gem 'ruby-debug19'
  end
end

group :test do
  gem 'fabrication'
  gem "timecop"
  gem 'capybara', '~> 1.0.0'
  gem "capybara-webkit"
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'mocha', :require => false
  gem 'simplecov', '0.4.2'
  gem 'simplecov-rcov'
  gem 'ci_reporter'
  gem 'webmock'
  gem 'test-unit'
  gem 'launchy'
  gem 'factory_girl_rails'
  gem 'faker'
end
