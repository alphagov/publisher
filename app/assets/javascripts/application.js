//= require_directory ./modules

//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib
//= require govuk_publishing_components/components/add-another
//= require govuk_publishing_components/components/govspeak
//= require govuk_publishing_components/components/reorderable-list
//= require govuk_publishing_components/components/table

// Analytics modules
//= require analytics_modules/ga4-form-setup
//= require analytics_modules/ga4-form-tracker
//= require analytics_modules/ga4-index-section-setup

window.GOVUK.approveAllCookieTypes()
window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
