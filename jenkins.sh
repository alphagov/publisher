#!/bin/bash -x

set -e

export FACTER_govuk_platform=test
export RAILS_ENV=test
export DISPLAY=":99"

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

bundle exec rake db:mongoid:drop
bundle exec rake ci:setup:minitest test
