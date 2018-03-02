#!/usr/bin/env groovy

library("govuk")

node('mongodb-2.4') {
  govuk.setEnvar("PUBLISHING_E2E_TESTS_COMMAND", "test-publisher")
  govuk.buildProject(sassLint: false, publishingE2ETests: true)
}
