'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4SearchResultsSetup () {}

  Ga4SearchResultsSetup.prototype.init = function () {
    this.trackEcommerce()
  }

  Ga4SearchResultsSetup.prototype.trackEcommerce = function () {
    var searchTarget = document.querySelector('[data-ga4-ecommerce]')
    var searchTerm = document.querySelector('input[name="search_text"]').value

    searchTarget.dataset.ga4SearchQuery = searchTerm

    if (searchTarget) {
      if (!searchTarget.hasAttribute('data-ga4-ecommerce-started')) {
        window.GOVUK.analyticsGa4.Ga4EcommerceTracker.init()
        searchTarget.setAttribute('data-ga4-ecommerce-started', true)
      }
    }
  }

  Modules.Ga4SearchResultsSetup = Ga4SearchResultsSetup
})(window.GOVUK.Modules)
