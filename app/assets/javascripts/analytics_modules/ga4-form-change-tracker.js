// This module is taken from Whitehall with some minor changes for Publisher
// There is work being done at the minute to move this into the Publishing Components gem
// This is a temporary file that will not be needed
// We can safely ignore this file WRT code reviews etc.

'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}

;(function (Modules) {
  function Ga4FormChangeTracker(form) {
    this.module = form
  }

  Ga4FormChangeTracker.prototype.init = function() {
    this.startModule()
  }

  // extra utility function for parsing
  // JSON string data attributes (convention
  // of the components library tracking)
  Ga4FormChangeTracker.prototype.getJson = function (target, attribute) {
    let dataContainer
    let data

    try {
      dataContainer = target.closest(`[${attribute}]`)
      data = dataContainer.getAttribute(attribute)
      return JSON.parse(data)
    } catch (e) {
      console.error(
        `GA4 configuration error: ${e.message}, attempt to access ${attribute} on ${target}`,
        window.location
      )
    }
  }

  Ga4FormChangeTracker.prototype.dateTimeComponent = function (target) {
    return (
      target.closest('.app-c-datetime-fields') ||
      target.closest('.govuk-date-input')
    )
  }

  Ga4FormChangeTracker.prototype.getSection = function (target, checkableValue) {
    const { id } = target
    const form = this.module
    const fieldset = target.closest('fieldset')
    const legend = fieldset && fieldset.querySelector('legend')
    const sectionContainer = form.closest('[data-ga4-section]')
    const label = form.querySelector(`label[for='${CSS.escape(id)}']`)
    const dateTimeComponent = this.dateTimeComponent(target)

    let section = sectionContainer && sectionContainer.dataset.ga4Section

    if (legend && (checkableValue || dateTimeComponent)) {
      section = legend ? legend.innerText : section

      if (dateTimeComponent) {
        // this is an intermediary measure!! need to rework the legends
        // for all datetime fields so they are more descriptive as
        // nested legends have inconsistent screenreader behaviour
        // this work can happen as part of moving datetime out of whitehall
        const dateTimeFieldset = dateTimeComponent.closest('fieldset')
        if (dateTimeFieldset) {
          const dateTimeLegend = dateTimeFieldset.querySelector('legend')
          if (dateTimeLegend && dateTimeLegend.innerText !== section) {
            section = `${dateTimeLegend.innerText} - ${section}`
          }
        }
      }
    } else {
      section = label ? label.innerText : section
    }

    return section
  }

  Ga4FormChangeTracker.prototype.handleDateComponent = function (target) {
    const isDateComponent = target.closest('.govuk-date-input')
    const value = target.value

    if (!isDateComponent)
      return typeof value === 'string' ? value.replace(/[\n\r]/g, ' ') : value

    // only track if completely filled in
    const inputs = [
      ...target.closest('.govuk-date-input').querySelectorAll('input')
    ]
    const allInputsSet = inputs.every((input) => input.value)

    if (allInputsSet) {
      return inputs.map((input) => input.value).join('/')
    }
  }

  // Ga4FormChangeTracker does not track form changes
  // so we need to define an extra function
  Ga4FormChangeTracker.prototype.trackFormChange = function (event) {
    const form = this.module

    if (!form) return

    if (!form.hasAttribute('data-ga4-form-change-tracking')) return

    const target = event.target
    const { type, id } = target

    if (type === 'search') return

    const index = this.getJson(target, 'data-ga4-index')
    const value = (event.detail && event.detail.value) || target.value

    // a radio or check input with a `name` and `value`
    // or an option of `value` within a `select` with `name`
    const checkableValue = form.querySelector(
      `#${CSS.escape(id)}[value="${CSS.escape(value)}"], #${CSS.escape(id)} [value="${CSS.escape(value)}"]`
    )

    let action = 'select'
    let text

    if (checkableValue) {
      // radio, check, option can have `:checked` pseudo-class
      if (!checkableValue.matches(':checked')) {
        action = 'remove'
      }

      text = checkableValue.innerText

      if (!text) {
        // it's not an option so has no innerText
        text = form.querySelector(`label[for='${CSS.escape(id)}']`).innerText
      }
    } else if (!text) {
      // it's a free form text field
      text = this.handleDateComponent(target)

      if (!text) return
    }

    window.GOVUK.analyticsGa4.core.applySchemaAndSendData(
      {
        ...index,
        section: this.getSection(
          target,
          checkableValue && checkableValue.matches(':not(option)')
        ),
        event_name: 'select_content',
        action,
        text: text.replace(/\r?\n|\r/g, '')
      },
      'event_data'
    )
  }

  // we need to override the default `startModule`
  // to add a listener to track changes to the form
  Ga4FormChangeTracker.prototype.startModule = function () {
    this.module.addEventListener('change', this.trackFormChange.bind(this))
  }

  Modules.Ga4FormChangeTracker = Ga4FormChangeTracker
})(window.GOVUK.Modules)
