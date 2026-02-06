'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4SearchSetup () {}

  Ga4SearchSetup.prototype.init = function () {
    console.log('Ga4SearchSetup init!')

    this.trackSearches()
  }

  Ga4SearchSetup.prototype.trackSearches = function () {
    console.log('trackSearches!')

    // TODO: Make this more specific
    var searchForm = document.querySelector('form')
    var tracker = new window.GOVUK.Modules.Ga4SearchTracker(searchForm)

    tracker.init()
  }

  Modules.Ga4SearchSetup = Ga4SearchSetup
})(window.GOVUK.Modules)
