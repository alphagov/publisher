EMAIL_GROUPS = {
    dev: [ENV.fetch('EMAIL_GROUP_DEV', 'govuk-dev@digital.cabinet-office.gov.uk')],
    business: [ENV.fetch('EMAIL_GROUP_BUSINESS', 'publisher-alerts-business@digital.cabinet-office.gov.uk')],
    citizen: [ENV.fetch('EMAIL_GROUP_CITIZEN', 'publisher-alerts-citizen@digital.cabinet-office.gov.uk')],
  }
