'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4IndexSectionSetup() {}

  Ga4IndexSectionSetup.prototype.init = function () {
    const modules = document.querySelectorAll(
      "[data-module~='ga4-index-section-setup']"
    )

    Array.from(modules).map((module) => {
      this.indexElements(module)
    })
  }

  Ga4IndexSectionSetup.prototype.indexElements = function (module) {
    // Find instances of these form elements: 
    // select, textarea, fieldset, input (except hidden, radio)
    const indexedElements = module.querySelectorAll(
      'select, textarea, fieldset, input:not([type="hidden"], [type="radio"])'
    )

    // Add data-attributes to element
    indexedElements.forEach((element, index) => {
      element.dataset.ga4Index = "{\"index_section\": " + index + ", \"index_section_count\": " + indexedElements.length + "}"
    })
  }

  Modules.Ga4IndexSectionSetup = Ga4IndexSectionSetup
})(window.GOVUK.Modules)
