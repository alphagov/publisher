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
    var section = form.closest('[data-ga4-section]').getAttribute('data-ga4-section')
    var toolName = form.closest('[data-ga4-tool-name]').getAttribute('data-ga4-tool-name')
    var dataModule = form.dataset.module || null
    var eventData = {
      event_name: 'form_response',
      type: 'edit',
      section: section,
      action: 'Save',
      tool_name: toolName
    }

    if (dataModule) {
      form.setAttribute('data-module', dataModule + ' ga4-form-tracker')
    } else {
      form.setAttribute('data-module', 'ga4-form-tracker')
    }
    form.setAttribute('data-ga4-form-include-text', '')
    form.setAttribute('data-ga4-form-change-tracking', '')
    form.setAttribute('data-ga4-form-record-json', '')
    form.setAttribute('data-ga4-form-use-text-count', '')
    form.setAttribute('data-ga4-form', JSON.stringify(eventData))

    // If the form contains date-input components add ga4-form-section data-attributes
    var dateInputs = form.querySelectorAll('.govuk-date-input') || null

    if (dateInputs) {
      Array.from(dateInputs).forEach(function (dateInput) {
        var fieldset = dateInput.closest('fieldset')
        fieldset.setAttribute('data-ga4-form-section', fieldset.querySelector('legend').textContent)
      })
    }
  }

  Ga4FormSetup.prototype.callFormChangeTracker = function (form) {
    var ga4FormChangeTracker = new window.GOVUK.Modules.Ga4FormChangeTracker(form)

    ga4FormChangeTracker.init()
  }

  Modules.Ga4FormSetup = Ga4FormSetup
})(window.GOVUK.Modules)
