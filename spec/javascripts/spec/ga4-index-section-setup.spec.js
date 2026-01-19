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
            <input type="text" name="text_1">
            <input type="text" name="text_1">
          </fieldset>
          <fieldset id="input_4">
            <input type="radio" name="radio_1">
            <input type="radio" name="radio_1">
          </fieldset>
          <div class="gem-c-add-another" id="input_5">
            <fieldset id="input_6"></fieldset>
          </div>
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
      expect(JSON.parse(input1.dataset.ga4Index).index_section_count).toBe(5)

      // textarea
      var input2 = module.querySelector('#input_2')
      expect(JSON.parse(input2.dataset.ga4Index).index_section).toBe(2)
      expect(JSON.parse(input2.dataset.ga4Index).index_section_count).toBe(5)

      // fieldset with inputs
      var input3 = module.querySelector('#input_3')
      expect(JSON.parse(input3.dataset.ga4Index).index_section).toBe(3)
      expect(JSON.parse(input3.dataset.ga4Index).index_section_count).toBe(5)

      // fieldset with radios
      var input4 = module.querySelector('#input_4')
      expect(JSON.parse(input4.dataset.ga4Index).index_section).toBe(4)
      expect(JSON.parse(input4.dataset.ga4Index).index_section_count).toBe(5)

      // "Add another" component
      var input5 = module.querySelector('#input_5')
      expect(JSON.parse(input5.dataset.ga4Index).index_section).toBe(5)
      expect(JSON.parse(input5.dataset.ga4Index).index_section_count).toBe(5)

      // fieldset within an "Add another" component
      var input6 = module.querySelector('#input_6')
      expect(input6.dataset.ga4Index).toBe(undefined)
   })
  })
})
