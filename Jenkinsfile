#!/usr/bin/env groovy

library("govuk")

node {
  // Run against the MongoDB 3.6 Docker instance on GOV.UK CI
  govuk.setEnvar("TEST_MONGODB_URI", "mongodb://127.0.0.1:27036/publisher")
  // Run against the Redis 6 Docker instance on GOV.UK CI
  govuk.setEnvar("REDIS_URL", "redis://127.0.0.1:63796")

  govuk.buildProject(
    brakeman: true,
  )
}
