describe('GA4FormSetup', function () {
  'use strict'

  var module, ga4FormSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-module="ga4-index-section-setup">
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

  describe('in initial state', function () {
    it('does nothing', function () {
      expect(3).toBe(3)
    })
  })
})
