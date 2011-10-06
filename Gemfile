source 'http://rubygems.org'

gem 'rails', '~> 3.0.10'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "mongoid", "~> 2.0"
gem "bson_ext", "~> 1.3"
gem 'erubis'
gem 'plek'

gem 'inherited_resources'
gem 'formtastic'
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

gem 'cdn_helpers', :git => 'git@github.com:alphagov/cdn_helpers.git', :tag => 'v0.8.3'

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
end

group :test do
  gem 'fabrication'
  gem "timecop"
  gem 'capybara', '~> 1.0.0'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'mocha', :require => false
  gem 'ruby-debug19'
  gem 'simplecov', '0.4.2'
  gem 'simplecov-rcov'
  gem 'ci_reporter'
  gem 'webmock'
  gem 'test-unit'
end
