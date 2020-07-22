EMAIL_GROUPS = {
  business: [ENV.fetch("EMAIL_GROUP_BUSINESS", "publisher-alerts-business@digital.cabinet-office.gov.uk")],
  citizen: [ENV.fetch("EMAIL_GROUP_CITIZEN", "publisher-alerts-citizen@digital.cabinet-office.gov.uk")],
  force_publish_alerts: [ENV.fetch("EMAIL_GROUP_FORCE_PUBLISH_ALERTS", "mainstream-force-publishing-alerts@digital.cabinet-office.gov.uk")],
}.freeze
