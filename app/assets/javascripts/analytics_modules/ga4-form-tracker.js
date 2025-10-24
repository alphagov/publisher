'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}
// window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
// window.GOVUK.analyticsGa4.core = window.GOVUK.analyticsGa4.core || {}
// window.GOVUK.analyticsGa4.core.trackFunctions = window.GOVUK.analyticsGa4.core.trackFunctions || {}
// window.GOVUK.Modules.Ga4FormTracker = window.GOVUK.Modules.Ga4FormTracker || {}

;(function (Modules) {
// ;(function (Ga4FormTracker) {
  function Ga4FormTracker(form) {
    this.module = form
  }

  Ga4FormTracker.prototype.init = function() {
    console.log('Ga4FormTracker init!')
    console.log('module: ', this.module)

    this.startModule()
  }

  // extra utility function for parsing
  // JSON string data attributes (convention
  // of the components library tracking)
  Ga4FormTracker.prototype.getJson = function (target, attribute) {
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

  Ga4FormTracker.prototype.dateTimeComponent = function (target) {
    return (
      target.closest('.app-c-datetime-fields') ||
      target.closest('.govuk-date-input')
    )
  }

  Ga4FormTracker.prototype.getSection = function (target, checkableValue) {
    const { id } = target
    const form = this.module
      // window.GOVUK.analyticsGa4.core.trackFunctions.findTrackingAttributes(
      //   event.target,
      //   this.trackingTrigger
      // )
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

  Ga4FormTracker.prototype.handleDateComponent = function (target) {
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

  // Ga4FormTracker does not track form changes
  // so we need to define an extra function
  Ga4FormTracker.prototype.trackFormChange = function (event) {
    console.log('trackFormChange!')
    console.log('trackingTrigger: ', this.trackingTrigger)

    const form = this.module
      // window.GOVUK.analyticsGa4.core.trackFunctions.findTrackingAttributes(
      //   event.target,
      //   this.trackingTrigger
      // )

    console.log('form: ', form)

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
  Ga4FormTracker.prototype.startModule = function () {
    console.log('startModule!')
    console.log('module: ', this.module)

    this.module.addEventListener('change', this.trackFormChange.bind(this))
    // Is this required?
    // Thought this was handled by the other module
    // this.module.addEventListener('submit', this.trackFormSubmit.bind(this))
  }

  // Ga4FormTracker.init()

  Modules.Ga4FormTracker = Ga4FormTracker
})(window.GOVUK.Modules)
// })(window.GOVUK.Modules.Ga4FormTracker)
