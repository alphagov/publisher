#!/bin/bash -x
source '/usr/local/lib/rvm'
bundle install --path "/home/jenkins/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
rm /var/lib/jenkins/jobs/Guides/workspace/public/images
rm /var/lib/jenkins/jobs/Guides/workspace/public/javascripts
rm /var/lib/jenkins/jobs/Guides/workspace/public/templates
rm /var/lib/jenkins/jobs/Guides/workspace/public/stylesheets

ln -s /var/lib/jenkins/jobs/Static/workspace/public/images /var/lib/jenkins/jobs/Guides/workspace/public/images
ln -s /var/lib/jenkins/jobs/Static/workspace/public/javascripts /var/lib/jenkins/jobs/Guides/workspace/public/javascripts
ln -s /var/lib/jenkins/jobs/Static/workspace/public/templates /var/lib/jenkins/jobs/Guides/workspace/public/templates
ln -s /var/lib/jenkins/jobs/Static/workspace/public/stylesheets /var/lib/jenkins/jobs/Guides/workspace/public/stylesheets

export DISPLAY=:99
bundle exec rake ci:setup:testunit test:units test:functionals test:integration
RESULT=$?
exit $RESULT
