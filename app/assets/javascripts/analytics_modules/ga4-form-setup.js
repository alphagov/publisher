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

      if (form.querySelector('select[multiple="multiple"]')) {
        this.setUpMultipleSelect(form)
      }
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
    form.setAttribute('data-ga4-form-use-select-count', '')
    form.setAttribute('data-ga4-form', JSON.stringify(eventData))

    // If the form contains date-input components add ga4-form-section data-attributes
    var dateInputs = form.querySelectorAll('.govuk-date-input') || null
    // TEST: if the for contains radio inputs add data-attributes to the containing fieldset
    var radioInputs = form.querySelector('input[type="radio"]') || null

    radioInputs.closest('fieldset').setAttribute('data-ga4-redact', true)
    radioInputs.closest('fieldset').setAttribute('data-ga4-redact-permit', "none, 3")

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

  // If there are "multiple" select elements we need to
  // set the "ga4-form-use-select-count" data-attribute
  // when multiple selections are made
  Ga4FormSetup.prototype.setUpMultipleSelect = function (form) {
    var select = form.querySelector('select')
    var optionsSelected = []

    select.addEventListener('change', function (e) {
      Array.from(e.target.options).forEach(function (option) {
        if (option.selected && !optionsSelected.includes(option)) {
          optionsSelected.push(option)
        } else if (!option.selected && optionsSelected.includes(option)) {
          optionsSelected = optionsSelected.filter(function (optionSelected) {
            return optionSelected !== option
          })
        }
      })

      if (optionsSelected.length > 1) {
        form.setAttribute('data-ga4-form-use-select-count', '')
      } else {
        form.removeAttribute('data-ga4-form-use-select-count')
      }
    })
  }

  Modules.Ga4FormSetup = Ga4FormSetup
})(window.GOVUK.Modules)
