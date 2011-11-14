#!/bin/bash -x

export FACTER_govuk_platform=test
export RAILS_ENV=test
export DISPLAY=":99"

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# DELETE STATIC SYMLINKS AND RECONNECT...
for d in images javascripts templates stylesheets; do
  rm -f public/$d
  ln -s ../../Static/public/$d public/
done

bundle exec rake ci:setup:testunit test
RESULT=$?
exit $RESULT
