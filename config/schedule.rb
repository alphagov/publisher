set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}
job_type :run_script,  'cd :path && RAILS_ENV=:environment script/:task'

every 5.minutes do
  run_script "mail_fetcher"
end

every :hour do
  rake "update_publisher_dashboard"
end

every :hour do
  rake "rummager:index"
end

every 1.day, :at => '5am' do
  rake "local_transactions:fetch"
end