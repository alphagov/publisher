require 'cucumber/rails'

require File.expand_path('../../../test/test_helper', __FILE__)

Capybara.default_selector = :css

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end