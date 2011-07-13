source 'http://rubygems.org'

gem 'rails', '~> 3.0.7'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "mongoid", "~> 2.0"
gem "bson_ext", "~> 1.3"
gem 'sinatra'
gem 'erubis'
gem 'httparty'

gem 'inherited_resources'
gem 'formtastic'
gem 'has_scope'
if ENV['BUNDLE_DEV']
  gem 'gds-sso', :path => '../gds-sso'
else
  gem 'gds-sso', :git => 'git@github.com:alphagov/gds-sso.git'
end
gem 'slimmer', :git => 'git@github.com:alphagov/slimmer.git'
gem 'cdn_helpers', :git => 'git@github.com:alphagov/cdn_helpers.git', :tag => 'v0.8.3'

gem 'govspeak', :git => 'git@github.com:alphagov/govspeak.git'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri', '1.4.1'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem "factory_girl_rails", "~> 1.1.rc1"
  gem "timecop"
end
