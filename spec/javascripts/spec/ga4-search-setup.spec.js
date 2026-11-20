describe('GA4SearchSetup', function () {
  'use strict'

  let module, ga4SearchSetup

  beforeEach(function () {
    const moduleHtml =
      `<form>
          <input type="search">
        </form>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)
    ga4SearchSetup = new window.GOVUK.Modules.Ga4SearchSetup(module)
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when initialised', function () {
    it('should initialise Ga4SearchTracker', function () {
      const ga4SearchTracker = window.GOVUK.Modules.Ga4SearchTracker
      const ga4SearchTrackerSpyInit = spyOn(ga4SearchTracker.prototype, 'init')

      ga4SearchSetup.init()

      expect(ga4SearchTrackerSpyInit).toHaveBeenCalled()
    })
  })
})
