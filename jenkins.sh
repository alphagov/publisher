#!/bin/bash -x
source '/usr/local/lib/rvm'
bundle install --path "/home/jenkins/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
for d in images javascripts templates stylesheets; do
  rm -f public/$d
  ln -s ../../../Static/$d public/
done

export DISPLAY=:99
bundle exec rake ci:setup:testunit test:units test:functionals test:integration
RESULT=$?
exit $RESULT
