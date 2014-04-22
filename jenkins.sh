#!/bin/bash -x

set -e

export RAILS_ENV=test

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

bundle exec rake db:mongoid:drop
bundle exec rake ci:setup:minitest default
