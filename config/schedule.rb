set :output, error: 'log/cron.error.log', standard: 'log/cron.log'

schedule_task_prefix = ENV.fetch('SCHEDULE_TASK_PREFIX', '/usr/local/bin/govuk_setenv publisher')
job_type :rake, "cd :path && #{schedule_task_prefix} bundle exec rake :task :output"
job_type :run_script, "cd :path && RAILS_ENV=:environment #{schedule_task_prefix} script/:task :output"

every 5.minutes do
  run_script "mail_fetcher"
end

every 1.hour do
  rake "reports:generate"
end
