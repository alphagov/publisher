#!/usr/bin/env groovy

library("govuk")

node {
  // Run against the MongoDB 3.6 Docker instance on GOV.UK CI
  govuk.setEnvar("TEST_MONGODB_URI", "mongodb://127.0.0.1:27036/publisher")

  govuk.setEnvar("PUBLISHING_E2E_TESTS_COMMAND", "test-publisher")
  govuk.buildProject(
    publishingE2ETests: true,
    brakeman: true,
  )
}
