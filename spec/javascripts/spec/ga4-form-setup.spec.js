describe('GA4FormSetup', function () {
  'use strict'

  var module, ga4FormSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-module="ga4-form-setup" data-ga4-section="The section name" data-ga4-tool-name="Answer">
        <form data-module="">
          <fieldset>
            <legend>Some date</legend>
            <div class="govuk-date-input"></div>
          </fieldset>
          <select multiple="multiple">
            <option></option>
            <option></option>
          </select>
        </form>
        <form data-module="some-other-module"></form>
      </div>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    ga4FormSetup = new window.GOVUK.Modules.Ga4FormSetup()
    ga4FormSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when loaded', function () {
    it('adds/updates the "data-module" parameter of the form', function () {
      var form, formGA4Data

      form = module.querySelectorAll('form')[0]
      formGA4Data = form.dataset

      expect(formGA4Data.module).toBe('ga4-form-tracker')

      form = module.querySelectorAll('form')[1]
      formGA4Data = form.dataset

      expect(formGA4Data.module).toBe('some-other-module ga4-form-tracker')
    })

    it('adds the correct parameters to the form', function () {
      var form = module.querySelectorAll('form')[0]
      var formGA4Data = form.dataset
      var formEventData = JSON.parse(formGA4Data.ga4Form)

      expect(formEventData.action).toBe('Save')
      expect(formEventData.event_name).toBe('form_response')
      expect(formEventData.section).toBe('The section name')
      expect(formEventData.tool_name).toBe('Answer')
      expect(formEventData.type).toBe('edit')
      expect(Object.keys(formGA4Data)).toContain('ga4FormIncludeText')
      expect(Object.keys(formGA4Data)).toContain('ga4FormChangeTracking')
      expect(Object.keys(formGA4Data)).toContain('ga4FormRecordJson')
      expect(Object.keys(formGA4Data)).toContain('ga4FormUseTextCount')
    })

    it('adds the correct parameters to the form elements', function () {
      var form = module.querySelectorAll('form')[0]

      expect(form.querySelector('fieldset').dataset.ga4FormSection).toBe('Some date')
    })
  })

  describe('when the form contains a multiple select element', function () {
    var form, select, options, change

    describe('the correct "data-module" attribute of the form is set', function () {
      beforeEach(function () {
        form = module.querySelectorAll('form')[0]
        select = form.querySelector('select')
        options = select.querySelectorAll('option')
        change = new Event('change')
      })

      describe('if one option is selected', function () {
        it('does not update the data-attribute of the form', function () {
          options[0].setAttribute('selected', 'selected')
          options[1].removeAttribute('selected')

          select.dispatchEvent(change)

          expect(form.dataset.ga4FormUseSelectCount).not.toBeDefined()
        })
      })

      describe('if two options are selected', function () {
        it('adds the relevant data-attribute to the form', function () {
          options[0].setAttribute('selected', 'selected')
          options[1].setAttribute('selected', 'selected')

          select.dispatchEvent(change)

          expect(form.dataset.ga4FormUseSelectCount).toBeDefined()
        })
      })

      describe('if a selected option is deselected', function () {
        it('removes the relevant "data-module" attribute of the form', function () {
          form.dataset.ga4FormUseSelectCount = true

          options[0].removeAttribute('selected')
          options[1].setAttribute('selected', 'selected')

          select.dispatchEvent(change)

          expect(form.dataset.ga4FormUseSelectCount).not.toBeDefined()
        })
      })
    })
  })
})
