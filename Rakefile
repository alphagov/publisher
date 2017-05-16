# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'rake/testtask' if Rails.env.test?
require 'ci/reporter/rake/minitest' if Rails.env.test?

Rake.application.options.trace = true

Rails.application.load_tasks

task default: [:lint, :test, 'jasmine:ci']
