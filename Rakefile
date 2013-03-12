# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'ci/reporter/rake/test_unit' if Rails.env.test?

Rake.application.options.trace = true

Publisher::Application.load_tasks
