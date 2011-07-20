#!/bin/bash -x
source '/usr/local/lib/rvm'
bundle install --path "/home/jenkins/bundles/${JOB_NAME}" --deployment
bundle exec rake db:setup
bundle exec rake db:migrate
export DISPLAY=:99
/etc/init.d/xvfb start
bundle exec rake test:units test:integration 
RESULT=$?
/etc/init.d/xvfb stop
exit $RESULT