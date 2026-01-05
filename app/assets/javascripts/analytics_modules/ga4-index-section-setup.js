'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4IndexSectionSetup () {}

  Ga4IndexSectionSetup.prototype.init = function () {
    const modules = document.querySelectorAll(
      "[data-module~='ga4-index-section-setup']"
    )

    Array.from(modules).forEach(function (module) {
      this.indexElements(module)
    }.bind(this))
  }

  Ga4IndexSectionSetup.prototype.indexElements = function (module) {
    var indexableElements = []

    // Find instances of these form elements:
    // select, textarea, fieldset, input (except hidden), input(not in fieldset), radio, add-another
    var elements = module.querySelectorAll(
      'select, textarea, fieldset, input:not([type="hidden"], [type="radio"]), .gem-c-add-another'
    )

    Array.from(elements).forEach(function (element) {
      if (element.type === 'fieldset' || element.closest('fieldset') == null) {
        // Exclude all elements within an "Add another" component
        // but include instances of "Add another" component
        if (!element.closest('.gem-c-add-another') || element.classList.contains('gem-c-add-another')) {
          indexableElements.push(element)
        }
      }
    })

    // Add data-attributes to element
    indexableElements.forEach((element, index) => {
      element.dataset.ga4Index = '{"index_section": ' + (index + 1).toString() + ', "index_section_count": ' + indexableElements.length + '}'
    })
  }

  Modules.Ga4IndexSectionSetup = Ga4IndexSectionSetup
})(window.GOVUK.Modules)
