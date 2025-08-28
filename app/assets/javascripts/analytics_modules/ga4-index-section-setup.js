'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules =
  window.GOVUK.analyticsGa4.analyticsModules || {}
;(function (Modules) {
  Modules.Ga4IndexSectionSetup = {
    init: function () {
      const moduleElements = document.querySelectorAll(
        "[data-module~='ga4-index-section-setup']"
      )

      moduleElements.forEach(function (moduleElement) {
        const indexedElements = moduleElement.querySelectorAll(
          'select, textarea, input:not([data-module~="select-with-search"] input):not([type="text"]):not([type="radio"]):not([type="checkbox"]):not([type="hidden"]), fieldset'
        )

        indexedElements.forEach((element, index) => {
          if (element.tagName === 'FIELDSET' || !element.closest('fieldset')) {
            const indexData = {
              index_section: index + 1,
              index_section_count: indexedElements.length
            }
            element.dataset.ga4Index = JSON.stringify(indexData)
            element.dataset.ga4IndexSection = index + 1

            if (element.closest('[data-module~="ga4-finder-tracker"]')) {
              element.dataset.ga4FilterParent = true
            }
          }
        })
      })
    }
  }
})(window.GOVUK.analyticsGa4.analyticsModules)
