describe('PasteHtmlToGovspeak', function () {
  'use strict'

  var module, pasteHtmlToGovspeak
  var pasteEvent, textarea

  function createHtmlPasteEvent (content) {
    var event = new Event('paste')

    // event.clipboardData = new ClipboardEvent('paste', {clipboardData: content, dataType: 'text/html'})
    event.clipboardData = {
      getData: (type) => {
        if (type === 'text/html') {
          return content // html
        }
      }
    }

    return event
  }

  function pasteContent(content) {
    console.log('pasteContent!')
    console.log('content: ', content)

    pasteEvent = new Event('paste')
    var clipboardEvent = new ClipboardEvent('paste', {clipboardData: {getData: 'text/html'}, dataType: 'text/html', data: content})

    console.log('clipboardEvent: ', clipboardEvent)

    // pasteEvent.clipboardData = {
    //   getData: function(content) { // (type) => {
    //     // if (type === 'text/html') {
    //       return content // html
    //     // }
    //   }
    // }

    console.log('pasteEvent: ', pasteEvent.clipboardData.getData())

    textarea.dispatchEvent(pasteEvent)

    // pasteEvent.clipboardData.setData(content)

    // var data =     

    // console.log('clipboardData: ', pasteEvent)




    // navigator.clipboard.readText(content).then(
    //   function(content) {
    //     textarea.innerText = content
    //   }
    // )
  }

  beforeEach(function () {
    var moduleHtml =
      `<textarea></textarea>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    pasteHtmlToGovspeak = new window.GOVUK.Modules.PasteHtmlToGovspeak(module)
    pasteHtmlToGovspeak.init()

    textarea = module.querySelector('textarea')
    textarea.addEventListener('paste', function(event) {
      console.log('paste!')
      console.log('event: ', event)

      // event.clipboardData.setData(content)

      console.log('clipboardData: ', event.clipboardData.getData('text/html'))

      this.value = event.clipboardData.getData('text/html')

      // event.preventDefault()

      // var data = event.clipboardData.getData('text/html')

      // console.log('data: ', data)
    //   var data = event.getData()

    })
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('on pasting HTML into a <textarea>', function () {
    it('does nothng', function () {
      expect(1).toEqual(1)
    })

    it('converts <h2> elements to GovSpeak', function() {
      // textarea = module.querySelector('textarea')
      // pasteContent('<h2>Heading level 2</h2>')
      textarea.dispatchEvent(createHtmlPasteEvent('<h2>Heading level 2</h2>'))

      expect(textarea.value).toEqual('##Heading level 2')
    })
  })
})
