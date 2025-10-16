describe('GA4IndexSectionSetup', function () {
  'use strict'

  var module, ga4IndexSectionSetup

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

    ga4IndexSectionSetup = new window.GOVUK.Modules.Ga4IndexSectionSetup()
    ga4IndexSectionSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('When the page loads', function () {
    it('adds the correct data attributes to the form input elements', function () {
      // input [type="text"]
      var input1 = module.querySelector('#input_1')
      expect(JSON.parse(input1.dataset.ga4Index).index_section).toBe(1)
      expect(JSON.parse(input1.dataset.ga4Index).index_section_count).toBe(3)

      // textarea
      var input2 = module.querySelector('#input_2')
      expect(JSON.parse(input2.dataset.ga4Index).index_section).toBe(2)
      expect(JSON.parse(input2.dataset.ga4Index).index_section_count).toBe(3)

      // fieldset
      var input3 = module.querySelector('#input_3')
      expect(JSON.parse(input3.dataset.ga4Index).index_section).toBe(3)
      expect(JSON.parse(input3.dataset.ga4Index).index_section_count).toBe(3)
    })
  })
})
