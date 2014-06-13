source 'https://rubygems.org'
source 'https://BnrJb6FZyzspBboNJzYZ@gem.fury.io/govuk/'

gem 'rails', '3.2.18'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '9.2.0'
end

if ENV['CONTENT_MODELS_DEV']
  gem "govuk_content_models", :path => '../govuk_content_models'
else
  gem "govuk_content_models", "12.1.0"
end

gem 'erubis'
gem 'formtastic', git: 'https://github.com/justinfrench/formtastic.git', branch: '2.1-stable'
gem 'formtastic-bootstrap', git: 'https://github.com/cgunther/formtastic-bootstrap.git', branch: 'bootstrap-2'
gem 'gds-api-adapters', '10.11.0'

gem "nested_form", git: 'https://github.com/alphagov/nested_form.git', branch: 'add-wrapper-class'

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', path: '../govspeak'
else
  gem 'govspeak', '1.2.0'
end

gem 'has_scope'
gem 'inherited_resources'
gem 'kaminari', '0.13.0'
gem 'logstasher', '0.4.8'
gem "mongoid_rails_migrations", "1.0.0"
gem 'null_logger'
gem 'plek', '1.4.0'

# TODO: This was previously pinned due to a replica set bug in >1.6.2
# Consider whether this still needs to be pinned when it is provided
# as a dependency of govuk_content_models
gem 'mongo', '1.7.1'

gem 'redis', '3.0.7', require: false # Only used in some importers
gem 'mlanett-redis-lock', '0.2.2' # Only used in some importers
gem 'rest-client', require: false # Only used in some importers
gem 'retriable', require: false # Only used in some importers
gem 'reverse_markdown', require: false # Only used in some importers

gem 'statsd-ruby', '~> 1.1.0', require: false
gem 'whenever', require: false

gem 'jquery-rails', '3.0.4'
gem 'less-rails-bootstrap'
gem 'unicorn', '4.3.1'

gem 'airbrake', '3.1.15'
gem 'sidekiq', '2.17.2'
gem 'sidekiq-statsd', '0.1.2'

group :assets do
  gem "therubyracer", "0.11.4"
  gem 'uglifier'
end

group :test do
  gem 'turn', '0.9.6'
  gem 'minitest', '3.3.0'
  gem 'shoulda'
  gem 'database_cleaner'

  gem 'capybara', '2.2.1'
  gem 'poltergeist', '1.5.0'
  gem 'launchy'

  gem 'webmock'
  gem 'mocha', '0.13.3', :require => false
  gem 'factory_girl_rails'
  gem 'faker', '1.1.2'

  gem "timecop"

  gem 'simplecov', '~> 0.6.4', :require => false
  gem 'simplecov-rcov', '~> 0.2.3', :require => false
  gem 'ci_reporter'
end
