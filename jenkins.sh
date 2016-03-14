#!/bin/bash -x

set -e

export RAILS_ENV=test

git clean -fdx

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats

# Clone govuk-content-schemas depedency for tests
rm -rf tmp/govuk-content-schemas
git clone git@github.com:alphagov/govuk-content-schemas.git tmp/govuk-content-schemas

# Lint changes introduced in this branch, but not for master
if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --diff \
    --cached \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    app test lib
fi

bundle exec rake db:mongoid:drop
GOVUK_CONTENT_SCHEMAS_PATH=tmp/govuk-content-schemas bundle exec rake ci:setup:minitest default
