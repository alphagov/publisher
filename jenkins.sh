#!/bin/bash -x
source '/usr/local/lib/rvm'
bundle install --path "/home/jenkins/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
cd /var/lib/jenkins/jobs/Guides/workspace/public
for d in images javascript templates stylesheets; do
  rm -f $d
  ln -s ../../../Static/$d .
done
cd -

export DISPLAY=:99
bundle exec rake ci:setup:testunit test:units test:functionals test:integration
RESULT=$?
exit $RESULT
