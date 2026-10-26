describe('PasteHtmlToGovspeak', function () {
  'use strict'

  var module, pasteHtmlToGovspeak, textarea, createClipboardPasteEvent, pasteHtml

  beforeAll(function () {
    createClipboardPasteEvent = function (content) {
      var event = new Event('paste')

      event.clipboardData = {
        getData: function () {
          return content
        }
      }

      return event
    }

    pasteHtml = function (content) {
      var event = createClipboardPasteEvent(content)
      textarea.dispatchEvent(event)
    }
  })

  beforeEach(function () {
    var moduleHtml = '<textarea></textarea>'

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)
    textarea = module.querySelector('textarea')

    pasteHtmlToGovspeak = new window.GOVUK.Modules.PasteHtmlToGovspeak(textarea)
    pasteHtmlToGovspeak.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('on pasting HTML into a <textarea>', function () {
    it('converts <h2> elements to GovSpeak', function () {
      pasteHtml('<h2>Heading level 2</h2>')
      expect(textarea.value).toEqual('## Heading level 2')
    })

    it('converts <h3> elements to GovSpeak', function () {
      pasteHtml('<h3>Heading level 3</h3>')
      expect(textarea.value).toEqual('### Heading level 3')
    })

    it('converts <h4> elements to GovSpeak', function () {
      pasteHtml('<h4>Heading level 4</h4>')
      expect(textarea.value).toEqual('#### Heading level 4')
    })

    it('converts <h5> elements to GovSpeak', function () {
      pasteHtml('<h5>Heading level 5</h5>')
      expect(textarea.value).toEqual('##### Heading level 5')
    })

    it('converts <h6> elements to GovSpeak', function () {
      pasteHtml('<h6>Heading level 6</h6>')
      expect(textarea.value).toEqual('###### Heading level 6')
    })

    it('converts <ul> elements to GovSpeak', function () {
      pasteHtml('<ul><li>bullet 1</li><li>bullet 2</li><li>bullet 3</li></ul>')
      expect(textarea.value).toEqual('- bullet 1\n- bullet 2\n- bullet 3')
    })

    it('converts <ol> elements to GovSpeak', function () {
      pasteHtml('<ol><li>Add numbers</li><li>Check numbers</li><li>Love numbers</li></ol>')
      expect(textarea.value).toEqual('1. Add numbers\n2. Check numbers\n3. Love numbers')
    })

    it('converts <a href> elements to GovSpeak', function () {
      pasteHtml('<a href="http://www.parliament.uk">UK Parliament</a>')
      expect(textarea.value).toEqual('[UK Parliament](http://www.parliament.uk)')
    })

    it('converts <a mailto> elements to GovSpeak', function () {
      pasteHtml('<a href="mailto:address@example.com">address@example.com</a>')
      expect(textarea.value).toEqual('<address@example.com>')
    })
  })
})
