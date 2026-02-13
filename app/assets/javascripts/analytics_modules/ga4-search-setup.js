'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4SearchSetup (module) {
    this.module = module
  }

  Ga4SearchSetup.prototype.init = function () {
    this.trackSearches(this.module)
  }

  Ga4SearchSetup.prototype.trackSearches = function (module) {
    var searchForm = module.querySelector('form')
    var tracker = new window.GOVUK.Modules.Ga4SearchTracker(searchForm)

    tracker.init()
  }

  Modules.Ga4SearchSetup = Ga4SearchSetup
})(window.GOVUK.Modules)
