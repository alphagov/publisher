describe('PasteHtmlToGovspeak', function () {
  'use strict'

  var module, pasteHtmlToGovspeak

  beforeEach(function () {
    var moduleHtml =
      `<textarea></textarea>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    pasteHtmlToGovspeak = new window.GOVUK.Modules.PasteHtmlToGovspeak(module)
    pasteHtmlToGovspeak.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('empty test', function () {
    it('does nothng', function () {
      expect(1).toEqual(2)
    })
  })
})
