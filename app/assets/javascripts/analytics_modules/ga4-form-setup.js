'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4FormSetup() {
    // Dunnno what this does - consider removing
    // trackedComponents: ['reorderable-list'],
    // this.forms
  }

  Ga4FormSetup.prototype.init = function () {
    console.log('Ga4FormSetup init!')

    var forms

    const modules = document.querySelectorAll(
      "[data-module~='ga4-form-setup']"
    )

    console.log('modules: ', modules)

    Array.from(modules).map((module) => {
      forms = module.querySelectorAll('form')
    })

    console.log('forms: ', forms)

    Array.from(forms).map((form) => {
      this.addDataAttributes(form)
      this.callFormTracker(form)
    })
  }

  Ga4FormSetup.prototype.addDataAttributes = function(form) {
    console.log('addDataAttributes!')
    console.log('form: ', form)

    // Needs defining so it can be added to the data-ga4-form
    var eventData = "{&quot;event_name&quot;:&quot;form_response&quot;,&quot;action&quot;:&quot;Save&quot;,&quot;section&quot;:&quot;Edit publication&quot;,&quot;type&quot;:&quot;edit&quot;,&quot;tool_name&quot;:&quot;publications&quot;}"

    // What does this do and is it needed?
    // Looks like it's specific to a component on WH we don't have (yet)
    // if (!form.querySelector(trackedComponentsSelector)) {
      form.setAttribute('data-ga4-form-change-tracking', '')
    // }

    // What does this do and is it needed?
    if (
      form.querySelectorAll(
        'fieldset, input:not([type="checkbox"],[type="hidden"],[type="radio"],[type="search"]), select'
      ).length > 1
    ) {
      console.log('Set these attributes!')
      // WH: only record JSON if number of fields larger than 1
      form.setAttribute('data-ga4-form-record-json', '')
      form.setAttribute('data-ga4-form-split-response-text', '')
    }

    form.setAttribute('data-ga4-form', eventData) // JSON.stringify(eventData)
    form.setAttribute('data-ga4-form-include-text', '')
    form.setAttribute('data-ga4-form-use-text-count', '')
    form.setAttribute('data-ga4-form-use-select-count', '')

    // this.callFormTracker(form)
  }

  // ga4 form attributes on whitehall
  //   data-ga4-form-change-tracking="" 
  //   data-ga4-form="{&quot;event_name&quot;:&quot;form_response&quot;,&quot;action&quot;:&quot;Save&quot;,&quot;section&quot;:&quot;Edit publication&quot;,&quot;type&quot;:&quot;edit&quot;,&quot;tool_name&quot;:&quot;publications&quot;}" 
  //   data-ga4-form-record-json="" 
  //   data-ga4-form-split-response-text="" 
  //   data-ga4-form-include-text="" 
  //   data-ga4-form-use-text-count="" 
  //   data-ga4-form-use-select-count="" 

  // on publisher
  // data-ga4-form-record-json="" 
  // data-ga4-form-split-response-text="" 
  // data-ga4-form="{&amp;quot;event_name&amp;quot;:&amp;quot;form_response&amp;quot;,&amp;quot;action&amp;quot;:&amp;quot;Save&amp;quot;,&amp;quot;section&amp;quot;:&amp;quot;Edit publication&amp;quot;,&amp;quot;type&amp;quot;:&amp;quot;edit&amp;quot;,&amp;quot;tool_name&amp;quot;:&amp;quot;publications&amp;quot;}" 
  // data-ga4-form-include-text="" 
  // data-ga4-form-use-text-count="" 
  // data-ga4-form-use-select-count="" 
  
  Ga4FormSetup.prototype.callFormTracker = function (form) {
    console.log('callFormTracker!')

    const ga4FormTracker = new window.GOVUK.Modules.Ga4FormTracker(form)

    console.log('ga4FormTracker: ', ga4FormTracker)

    ga4FormTracker.init()
  }

  // Modules.Ga4FormSetup = {
  //   // Dunnno what this does - consider removing
  //   trackedComponents: ['reorderable-list'],

  //   init: function () {
  //     console.log('Ga4FormSetup init!')

  //     const $modules = document.querySelectorAll(
  //       "[data-module~='ga4-form-setup']"
  //     )

  //     // console.log('$modules: ', $modules)

  //     const trackedComponentsSelector = Modules.Ga4FormSetup.trackedComponents
  //       .map((trackedComponent) => `[data-module~="${trackedComponent}"]`)
  //       .join(',')

  //     // console.log('trackedComponentsSelector: ', trackedComponentsSelector)

  //     $modules.forEach(($module) => {
  //       const forms = $module.querySelectorAll(
  //         "form:not([data-module~='ga4-finder-tracker']):not([data-module~='ga4-form-tracker'])"
  //       )

  //       forms.forEach(function (form) {
  //         // console.log('form: ', form)

  //         if (!form.querySelector(trackedComponentsSelector)) {
  //           form.setAttribute('data-ga4-form-change-tracking', '')
  //         }

  //         // Neither of these are currently present on Publisher
  //         // Guess they need to be
  //         const sectionContainer = form.closest('[data-ga4-section]')
  //         const documentTypeContainer = form.closest('[data-ga4-document-type]')

  //         // console.log('sectionContainer: ', sectionContainer)
  //         // console.log('documentTypeContainer: ', documentTypeContainer)

  //         let eventData = {
  //           event_name: 'form_response',
  //           action: 'Save'
  //         }

  //         if (sectionContainer) {
  //           eventData.section =
  //             sectionContainer.getAttribute('data-ga4-section')
  //         }

  //         if (documentTypeContainer) {
  //           const [type, toolName] =
  //             documentTypeContainer.dataset.ga4DocumentType.split('-')

  //           const synonyms = {
  //             create: 'new',
  //             update: 'edit'
  //           }

  //           eventData = {
  //             ...eventData,
  //             type: synonyms[type] || type,
  //             tool_name: toolName
  //           }

  //           // console.log('eventData: ', eventData)
  //         }

  //         form.setAttribute('data-ga4-form', JSON.stringify(eventData))

  //         if (
  //           form.querySelectorAll(
  //             'fieldset, input:not([type="checkbox"],[type="hidden"],[type="radio"],[type="search"]), select'
  //           ).length > 1
  //         ) {
  //           // only record JSON if number of fields larger than 1
  //           form.setAttribute('data-ga4-form-record-json', '')
  //           form.setAttribute('data-ga4-form-split-response-text', '')
  //         }

  //         form.setAttribute('data-ga4-form-include-text', '')
  //         form.setAttribute('data-ga4-form-use-text-count', '')
  //         form.setAttribute('data-ga4-form-use-select-count', '')
  //         new window.GOVUK.Modules.Ga4FormTracker(form).init()

  //         form.addEventListener('submit', this.onSubmit)
  //       }, this)
  //     })
  //   },

  //   onSubmit: (event) => {
  //     // on forms we have multiple submit buttons so need to "guess"
  //     // the action from the focused element on submit

  //     const form = event.target.closest('form')

  //     const activeElement = document.activeElement

  //     try {
  //       const dataGa4Form = JSON.parse(form.getAttribute('data-ga4-form'))

  //       dataGa4Form.action = activeElement.textContent

  //       form.setAttribute('data-ga4-form', JSON.stringify(dataGa4Form))
  //     } catch (error) {
  //       console.log(error)
  //     }
  //   }
  // }
  Modules.Ga4FormSetup = Ga4FormSetup
})(window.GOVUK.Modules)
