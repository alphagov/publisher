'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4FormSetup () {}

  Ga4FormSetup.prototype.init = function () {
    var forms
    var modules = document.querySelectorAll(
      "[data-module~='ga4-form-setup']"
    )

    Array.from(modules).forEach(function (module) {
      forms = module.querySelectorAll('form')
    })

    Array.from(forms).forEach(function (form) {
      this.addDataAttributes(form)
      this.callFormChangeTracker(form)
    }.bind(this))
  }

  Ga4FormSetup.prototype.addDataAttributes = function (form) {
    var dataModule = form.dataset.module
    var eventData = {
      event_name: 'form_response',
      type: 'edit',
      section: 'Edit edition',
      action: 'Save',
      tool_name: 'publisher'
    }

    form.setAttribute('data-module', dataModule + ' ga4-form-tracker')
    form.setAttribute('data-ga4-form-include-text', '')
    form.setAttribute('data-ga4-form-change-tracking', '')
    form.setAttribute('data-ga4-form-record-json', '')
    form.setAttribute('data-ga4-form-use-text-count', '')
    form.setAttribute('data-ga4-form', JSON.stringify(eventData))
  }

  Ga4FormSetup.prototype.callFormChangeTracker = function (form) {
    var ga4FormTracker = new window.GOVUK.Modules.Ga4FormChangeTracker(form)

    ga4FormTracker.init()
  }

  Modules.Ga4FormSetup = Ga4FormSetup
})(window.GOVUK.Modules)
