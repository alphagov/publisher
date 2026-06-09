'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.vars = window.GOVUK.vars || {}
window.GOVUK.vars.extraDomains = [
  {
    name: 'production',
    domains: ['publisher.publishing.service.gov.uk'],
    initialiseGA4: true,
    id: 'GTM-KHZP7S7Q',
    gaProperty: 'UA-26179049-6'
  },
  {
    name: 'staging',
    domains: ['publisher.staging.publishing.service.gov.uk'],
    initialiseGA4: false
  },
  {
    name: 'integration',
    domains: ['publisher.integration.publishing.service.gov.uk'],
    initialiseGA4: true,
    id: 'GTM-KHZP7S7Q',
    auth: 'GoGeIsCL2PK9Dv50tgM6Lg',
    preview: 'env-172'
  }
]
