//= require_directory ./modules

//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib
//= require govuk_publishing_components/components/add-another
//= require govuk_publishing_components/components/govspeak
//= require govuk_publishing_components/components/reorderable-list
//= require govuk_publishing_components/components/table

// Analytics modules
//= require govuk_publishing_components/analytics-ga4/ga4-ecommerce-tracker
//= require govuk_publishing_components/analytics-ga4/ga4-form-change-tracker
//= require analytics_modules/ga4-form-setup
//= require analytics_modules/ga4-index-section-setup
//= require analytics_modules/ga4-search-setup
//= require analytics_modules/ga4-search-results-setup

window.GOVUK.approveAllCookieTypes()
window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
