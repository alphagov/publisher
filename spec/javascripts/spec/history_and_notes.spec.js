window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}

describe('History and Notes component', function () {
  'use strict'

  var module, historyAndNotes

  beforeEach(function () {
    var moduleHtml =
      `<p>Fixture</p>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    historyAndNotes = new window.GOVUK.Modules.HistoryAndNotes(module)
    historyAndNotes.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('A test', function () {
    it('should do something', function () {
      expect(1).toEqual('2')
    })
  })
})
