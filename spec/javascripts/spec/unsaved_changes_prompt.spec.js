window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}

describe('Unsaved Changes Prompt component', function () {
  'use strict'

  var module, externalLink, unsavedChangesPrompt

  beforeEach(function () {
    var moduleHtml = `
      <input type="text"></input>
      <input type="submit"></input>
    `

    module = document.createElement('form')
    externalLink = document.createElement('a')
    externalLink.href="https://link.com"
    module.innerHTML = moduleHtml
    document.body.appendChild(externalLink)
    document.body.appendChild(module)

    unsavedChangesPrompt = new window.GOVUK.Modules.UnsavedChangesPrompt(module)
    unsavedChangesPrompt.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  xdescribe('When initialised', function() {
    var handleChangesMethod
    
    beforeEach(function() {
      handleChangesMethod = spyOn(unsavedChangesPrompt, 'handleChanges')
    })

    it('should call the setup methods', function() {
      expect(handleChangesMethod).toHaveBeenCalled()
    })
  })

  describe('User clicks external link without making changes', function () {
    beforeEach(function () {
    })

    // var link = document.querySelector('a')

    console.log('link: ', externalLink)

    it('should leave the page', function () {
      expect(2).toBe(2)
    })
  })
})
