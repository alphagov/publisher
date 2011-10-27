source 'http://rubygems.org'

gem 'oauth2', '0.4.1'
gem 'oa-core', '0.2.6'
gem 'oa-oauth', '0.2.6'

group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'rails', '3.1.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "mongoid", "~> 2.3"
gem "bson_ext", "~> 1.4"
gem 'erubis'
gem 'plek', :git => 'git@github.com:alphagov/plek.git'
gem 'pethau'
gem 'marples'
gem 'null_logger'

gem 'inherited_resources'
gem 'formtastic', '~> 2.0.0'
gem 'has_scope'
gem 'stomp', '1.1.9'

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

gem 'cdn_helpers', :git => 'git@github.com:alphagov/cdn_helpers.git'

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', :path => '../govspeak'
else
  gem 'govspeak', :git => 'git@github.com:alphagov/govspeak.git'
end


gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'

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
