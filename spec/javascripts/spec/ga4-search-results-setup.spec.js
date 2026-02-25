describe('GA4SearchResultsSetup', function () {
  'use strict'

  var module, ga4SearchResultsSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-ga4-ecommerce>
        <form>
          <input name="search_text">
        </form>
      </div>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)
    ga4SearchResultsSetup = new window.GOVUK.Modules.Ga4SearchResultsSetup(module)
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when initialised', function () {
    it('should initialise Ga4EcommerceTracker', function () {
      var ga4EcommerceTracker = window.GOVUK.analyticsGa4.Ga4EcommerceTracker
      var ga4EcommerceTrackerSpyInit = spyOn(ga4EcommerceTracker, 'init')

      ga4SearchResultsSetup.init()

      expect(ga4EcommerceTrackerSpyInit).toHaveBeenCalled()
    })
  })
})
