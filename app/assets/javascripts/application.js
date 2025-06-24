//= require_directory ./modules

//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib
//= require govuk_publishing_components/components/add-another
//= require govuk_publishing_components/components/govspeak
//= require govuk_publishing_components/components/table

//= require analytics_modules/ga4-button-setup.js
//= require analytics_modules/ga4-finder-setup.js
//= require analytics_modules/ga4-index-section-setup.js
//= require analytics_modules/ga4-paste-tracker.js

window.GOVUK.approveAllCookieTypes()
window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
