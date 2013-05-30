# This file is overwritten on deploy
set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}
job_type :rake, 'cd :path && /usr/local/bin/govuk_setenv publisher bundle exec rake :task :output'
job_type :run_script,  'cd :path && RAILS_ENV=:environment /usr/local/bin/govuk_setenv publisher script/:task :output'

every 1.day, :at => '5am' do
  rake "local_transactions:fetch"
end
