# GA4 tracking

Tracking is added to Publisher via GA4. The full documentation is avaialable in [GA4 Publishing Implementation guide](https://docs.google.com/document/d/19RaqZttDTZXsgX4k87wAAOhsol1STM3iTPPPKNlXRl0/edit?tab=t.0#heading=h.eo3rk3rxuz4n).

Via this means we are tracking:
- Page views
- Navigation
- Form interactions

Most of the code exists in the govuk_publishing_components gem. On publisher we are setting up various parameters on elements to make use of this. Our approach is to add these dynamically on page load via JavaScript set-up modules.

## Testing locally

Tracking can be tested locally with these steps:
- ensure that the "Ga4 form tracking" feature is set to "On" via FlipFlop
- ensure that "Preserve log" is set to "On" in the browser console
- run `window.GOVUK.analyticsGa4.showDebug = true` in the browser console. The console will then display the tracking data for all user interactions with the form as they occur.

Running `window.dataLayer` in the browser console at any point will display the data that has been collected during user interactions with the page. In this work we are interested in the "event_data" events. There should be one of these for each user event with the form since the page was loaded.

## Automated tests

There are:
- JavaScript Unit Tests for each set-up module:
  - spec/javascripts/spec/ga4-form-setup.spec.js
  - spec/javascripts/spec/ga4-index-section-setup.spec.js
- Rails integration tests for each page that uses the set-up modules:
  - test/integration/ga4_tracking_test.rb
