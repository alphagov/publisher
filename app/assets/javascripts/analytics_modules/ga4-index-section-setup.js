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
    // select, textarea, input (except hidden)
    const indexedElements = module.querySelectorAll(
      'select, textarea, input:not([type="hidden"])'
    )

    // Add data-attributes to element
    indexedElements.forEach((element, index) => {
      element.dataset.ga4Index = "{\"index_section\": " + index + ", \"index_section_count\": " + indexedElements.length + "}"
    })
  }

// // ;(function (analyticsGa4.analyticsModules) {
// //   analyticsGa4.analyticsModules.Ga4IndexSectionSetup = {
//     init: function () {
//       // console.log('Ga4IndexSectionSetup init!')

//       const moduleElements = document.querySelectorAll(
//         "[data-module~='ga4-index-section-setup']"
//       )

//       moduleElements.forEach(function (moduleElement) {
//         // An indexed section is either a single element
//         // or set of elements that changes one value of
//         // a form. Therefore we don't want to index:
//         //
//         // - individual radio buttons because they change
//         //   one value of a single value
//         // - individual checkboxes if they're part of a
//         //   group of checkboxes that change a single value
//         //
//         // Additionally we don't want to index:
//         // - the search within a SelectWithSearch component as it doesn't
//         //   change the value of the form
//         // - a hidden input because the user can't interact with it
//         const indexedElements = moduleElement.querySelectorAll(
//           'select, textarea, input:not([data-module~="select-with-search"] input):not([type="hidden"])'
//         )

//         let index = 0

//         Array.from(indexedElements)
//           .map((element) => {
//             // field could have a hidden element if it is
//             // a checkbox so need to exclude hidden
//             const multipleElements = moduleElement.querySelectorAll(
//               `[name='${CSS.escape(element.name)}']:not([type="hidden"])`
//             )
//             // if name is split then `name` will be of format
//             // `name[Ni]` where `N` is index of split field
//             const splitField = element.name.match(/^.*\(\di\)?.$/)

//             const indexableElement =
//               (multipleElements.length > 1 || splitField
//                 ? element.closest('fieldset')
//                 : element) || element

//             if (!indexableElement.dataset.ga4IndexSection) {
//               indexableElement.dataset.ga4IndexSection = index
//               index += 1
//             }

//             if (
//               indexableElement.closest('[data-module~="ga4-finder-tracker"]')
//             ) {
//               // required attribute for `ga4-finder-tracker`
//               // assumes that index values will come from
//               // an element with `ga4-filter-parent` set
//               indexableElement.dataset.ga4FilterParent = true
//             }

//             return indexableElement
//           })
//           .forEach((element) => {
//             if (element.dataset.ga4IndexSection) {
//               const indexData = {
//                 index_section: +element.dataset.ga4IndexSection,
//                 index_section_count: index
//               }
//               element.dataset.ga4Index = JSON.stringify(indexData)
//             }
//           })
//       })
//     }
  // }

  Modules.Ga4IndexSectionSetup = Ga4IndexSectionSetup
})(window.GOVUK.Modules)
