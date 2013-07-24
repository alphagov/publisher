# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'ci/reporter/rake/minitest' if Rails.env.test?

Rake.application.options.trace = true

Publisher::Application.load_tasks

Rake.application['default'].prerequisites.delete('test') if Rake.application['default']
task :default => [:'test:units', :'test:functionals', :check_for_bad_time_handling]
