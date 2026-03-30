'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4FormErrorsSetup (module) {
    this.module = module
  }

  Ga4FormErrorsSetup.prototype.init = function () {
    console.log('Ga4FormErrorsSetup | init!')
    console.log('module:', this.module)

    this.addAutoAttributes(this.module)
  }

  Ga4FormErrorsSetup.prototype.addAutoAttributes = function(module) {
    var ga4AutoAttributes = JSON.parse(module.dataset.ga4Auto)
    var errors = module.querySelectorAll('.gem-c-error-summary__list-item a')
    var sections = []
    var texts = []

    Array.from(errors).forEach(function(error) {
      sections.push(document.querySelector(error.hash).parentNode.querySelector('label').textContent)
      texts.push(error.text)
    })

    ga4AutoAttributes.section = sections.join(', ')
    ga4AutoAttributes.text = texts.join(', ')
    module.dataset.ga4Auto = JSON.stringify(ga4AutoAttributes)
  }

  Modules.Ga4FormErrorsSetup = Ga4FormErrorsSetup
})(window.GOVUK.Modules)
