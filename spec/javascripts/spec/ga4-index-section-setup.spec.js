describe('GA4IndexSectionSetup', function () {
  'use strict'

  var module, ga4IndexSectionSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-module="ga4-index-section-setup">
        <form>
          <input type="text">
        </form>
      </div>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    ga4IndexSectionSetup = new window.GOVUK.Modules.Ga4IndexSectionSetup
    ga4IndexSectionSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('When the page loads', function () {
    it('adds the correct data attributes to the form input elements', function () {
      const inputs = module.querySelectorAll('input')

      Array.from(inputs).map((input) => {
        expect(JSON.parse(input.dataset.ga4Index).index_section).toBe(0)
        expect(JSON.parse(input.dataset.ga4Index).index_section_count).toBe(1)
      })
    })
  })
})
