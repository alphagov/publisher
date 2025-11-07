describe('GA4FormSetup', function () {
  'use strict'

  var module, ga4FormSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-module="ga4-form-setup" data-ga4-section="The section name">
        <form></form>
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
    it('adds/updates the "data-module" parameter of the form', function() {
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
      expect(formEventData.tool_name).toBe('publisher')
      expect(formEventData.type).toBe('edit')
      expect(Object.keys(formGA4Data)).toContain('ga4FormIncludeText')
      expect(Object.keys(formGA4Data)).toContain('ga4FormChangeTracking')
      expect(Object.keys(formGA4Data)).toContain('ga4FormRecordJson')
      expect(Object.keys(formGA4Data)).toContain('ga4FormUseTextCount')
    })
  })
})
