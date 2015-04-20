#!/bin/bash -x

set -e

export RAILS_ENV=test

git clean -fdx

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# Clone govuk-content-schemas depedency for tests
rm -rf tmp/govuk-content-schemas
git clone git@github.com:alphagov/govuk-content-schemas.git tmp/govuk-content-schemas

bundle exec rake db:mongoid:drop
GOVUK_CONTENT_SCHEMAS_PATH=tmp/govuk-content-schemas bundle exec rake ci:setup:minitest default
