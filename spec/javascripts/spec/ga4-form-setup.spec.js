describe('GA4FormSetup', function () {
  'use strict'

  var module, ga4FormSetup

  beforeEach(function () {
    // Probably don't need the full form but only the <form> element itself
    var moduleHtml =
      `<div data-module="ga4-form-setup">
        <form>
          <input type="text" id="input_1">
          <textarea id="input_2"></textarea>
          <fieldset id="input_3">
            <input type="radio" name="radio_1">
            <input type="radio" name="radio_1">
          </fieldset>
        </form>
      </div>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    ga4FormSetup = new window.GOVUK.Modules.Ga4FormSetup
    ga4FormSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when loaded', function () {
    // TODO: make this test work
    // Probably should be init not getJson
    xit('starts the FormTracker module', function () {
      const Ga4FormTrackerSpy = spyOn(new window.GOVUK.Modules.Ga4FormTracker(), 'getJson')

      expect(Ga4FormTrackerSpy).toHaveBeenCalled()
    })
  })
})
