window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}
// window.GOVUK.analyticsModules = window.GOVUK.analyticsModules || {}

// window.GOVUK = window.GOVUK || {}
// window.GOVUK.Modules = window.GOVUK.Modules || {};

describe('GA4 Index Section Setup', function () {
  'use strict'

  // console.log('analyticsModules: ', window.GOVUK.analyticsGa4.analyticsModules)
  // console.log('analyticsGa4: ', window.GOVUK.analyticsGa4)
  console.log('GOVUK: ', window.GOVUK)
  // console.log('analyticsModules: ', window.GOVUK.analyticsModules)

  var module, ga4IndexSectionSetup

  beforeEach(function () {
    // var moduleHtml =
    //   ``

    // module = document.createElement('div')
    // module.innerHTML = moduleHtml
    // document.body.appendChild(module)

    ga4IndexSectionSetup = new window.GOVUK.analyticsModules.Ga4IndexSectionSetup
    // ga4IndexSectionSetup = new window.GOVUK.Modules.Ga4IndexSectionSetup
    ga4IndexSectionSetup.init()
  })

  afterEach(function () {
    // document.body.removeChild(module)
  })

  describe('Tests nothing yet', function () {
    it('should do nothing meaningful', function () {
      expect(1).toBe(1)
    })
  })
})
