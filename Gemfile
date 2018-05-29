source 'https://rubygems.org'

gem 'bootstrap-kaminari-views', '0.0.5'
gem 'diffy', '3.2.1'
gem 'erubis'
gem 'formtastic', '3.1.5'
gem 'formtastic-bootstrap', '3.1.1'
gem 'gds-sso', '~> 13.6'
gem 'gds-api-adapters', '~> 52'
gem 'govspeak', '~> 5.6.0'
gem 'govuk_admin_template', '~> 6.6'
gem 'govuk_app_config', '~> 1.5.0'
gem 'govuk_sidekiq', '~> 3.0.0'
gem 'has_scope'
gem 'inherited_resources'
gem 'jquery-ui-rails', '~> 6.0'
gem 'kaminari', '~> 1.1'
gem 'kaminari-mongoid', '1.0.1'
gem 'mlanett-redis-lock', '0.2.7' # Only used in some importers
gem 'momentjs-rails', '2.20.1'
gem 'mongo', '2.4.3'
gem 'mongoid', '~> 6.1'
gem "mongoid_rails_migrations", git: "https://github.com/alphagov/mongoid_rails_migrations", branch: "avoid-calling-bundler-require-in-library-code-v1.1.0-plus-mongoid-v5-fix"
gem "mongoid-sadstory"
gem 'mousetrap-rails', '1.4.6'
gem "nested_form", git: 'https://github.com/alphagov/nested_form.git', branch: 'add-wrapper-class'
gem 'null_logger'
gem 'plek', '2.1.1'
gem 'rails', '~> 5.2'
gem 'rails_autolink', '1.1.6'
gem 'rest-client', require: false # Only used in some importers
gem 'retriable', require: false # Only used in some importers
gem 'reverse_markdown', '1.1.0', require: false # Only used in some importers
gem 'sass-rails', '~> 5.0'
gem 'select2-rails', '3.5.9.1' # Updating this will mean updating the styling as 4 & > have a new approach to class names.
gem 'selectize-rails', '0.12.4.1'
gem 'state_machines', '~> 0.4'
gem 'state_machines-mongoid', '~> 0.1'
gem 'uglifier', '4.1.10'
gem 'whenever', require: false

group :test do
  gem 'capybara', '2.18.0'
  gem 'ci_reporter_minitest', '1.0.0'
  gem 'database_cleaner', '1.7.0'
  gem 'factory_bot_rails'
  gem 'govuk-content-schema-test-helpers', '~> 1.6'
  gem 'minitest-reporters'
  gem 'mocha', '1.5.0'
  gem 'poltergeist', '1.18.1'
  gem 'rails-controller-testing'
  gem 'shoulda', '3.5.0'
  gem 'simplecov', '~> 0.16.1', require: false
  gem 'simplecov-rcov', '~> 0.2.3', require: false
  gem "timecop", '0.9.1'
  gem 'webmock', '~> 3.4.1'
end

group :development do
  gem 'state_machines-graphviz'
end

group :development, :test do
  gem 'govuk-lint', '~> 3.8.0'
  gem 'jasmine', '2.5.2'
  gem 'jasmine-core', '2.5.2'
  gem 'rack', '2.0.5'
  gem 'pry-byebug'
end
