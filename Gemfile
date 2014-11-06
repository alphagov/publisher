source 'https://rubygems.org'

gem 'rails', '3.2.18'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '9.3.0'
end

if ENV['CONTENT_MODELS_DEV']
  gem "govuk_content_models", :path => '../govuk_content_models'
else
  gem "govuk_content_models", "23.0.0"
end

gem 'erubis'
gem 'govuk_admin_template', '1.1.6'
gem 'formtastic', '2.3.0'
gem 'formtastic-bootstrap', '3.0.0'
gem 'gds-api-adapters', '14.10.0'

gem "nested_form", git: 'https://github.com/alphagov/nested_form.git', branch: 'add-wrapper-class'

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', path: '../govspeak'
else
  gem 'govspeak', '~> 3.1.0'
end

gem 'has_scope'
gem 'inherited_resources'
gem 'kaminari', '0.13.0'
gem 'bootstrap-kaminari-views', '0.0.3'
gem 'logstasher', '0.4.8'
gem "mongoid_rails_migrations", "1.0.0"
gem 'null_logger'
gem 'plek', '1.9.0'
gem 'diffy', '3.0.6'

# TODO: This was previously pinned due to a replica set bug in >1.6.2
# Consider whether this still needs to be pinned when it is provided
# as a dependency of govuk_content_models
gem 'mongo', '1.7.1'

gem 'redis', '3.0.7', require: false # Only used in some importers
gem 'mlanett-redis-lock', '0.2.2' # Only used in some importers
gem 'rest-client', require: false # Only used in some importers
gem 'retriable', require: false # Only used in some importers
gem 'reverse_markdown', '0.3.0', require: false # Only used in some importers

gem 'statsd-ruby', '~> 1.1.0', require: false
gem 'whenever', require: false

gem 'unicorn', '4.3.1'

gem 'airbrake', '3.1.15'
gem 'sidekiq', '2.17.2'
gem 'sidekiq-statsd', '0.1.2'

group :assets do
  gem "therubyracer", "0.11.4"
  gem 'sass-rails', '3.2.6'
  gem 'uglifier', '1.2.7'
end

group :test do
  gem 'turn', '0.9.6'
  gem 'minitest', '3.3.0'
  gem 'shoulda', '3.1.1'
  gem 'database_cleaner', '0.8.0'

  gem 'capybara', '2.2.1'
  gem 'poltergeist', '1.5.0'
  gem 'launchy', '2.1.1'

  gem 'webmock', '1.8.7'
  gem 'mocha', '0.13.3', :require => false
  gem 'factory_girl_rails'
  gem 'faker', '1.1.2'

  gem "timecop", '0.4.4'

  gem 'simplecov', '~> 0.6.4', :require => false
  gem 'simplecov-rcov', '~> 0.2.3', :require => false
  gem 'ci_reporter', '1.7.0'
end

group :development, :test do
  gem 'jasmine', '2.0.2'
end
