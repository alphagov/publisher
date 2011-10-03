set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}
job_type :run_script,  'cd :path && RAILS_ENV=:environment script/:task'

every 1.hour do
  run_script "mail_fetcher"
end
