/* globals Mousetrap */

describe('An ajax save module', function () {
  'use strict'

  var ajaxSave,
    element,
    form

  beforeEach(function () {
    element = $('<div>' +
      '<div class="page-title"></div>' +
      '<form action="some/url">' +
      '<div class="js-status-message"></div>' +
      '<div class="form-group">' +
      '  <div class="form-label">' +
      '    <label for="edition_test">Test</label>' +
      '  </div>' +
      '  <div class="form-wrapper">' +
      '    <input class="" type="text" value="prefilled value" name="edition_test" id="edition_test">' +
      '  </div>' +
      '  <ul class="help-block error-block"></ul>' +
      '</div>' +
      '<div class="form-group">' +
      '  <div class="form-wrapper">' +
      '    <label for="edition_another">' +
      '      <input type="checkbox" value="1" name="edition_another" id="edition_another">' +
      '      Another' +
      '    </label>' +
      '  </div>' +
      '  <ul class="help-block error-block"></ul>' +
      '</div>' +
      '<input class="js-no-ajax" type="text" name="fake-file-input">' +
      '<input class="js-no-ajax" type="checkbox" name="remove-file-checkbox" value="1">' +
      '<input type="submit" class="js-save" value="Save">' +
      '</form>' +
      '</div>'
    )

    $('body').append(element)
    form = element.find('form')
    ajaxSave = new GOVUKAdmin.Modules.AjaxSave()
    ajaxSave.start(form)

    var submitCallbackSpy = jasmine.createSpy('some/url').and.returnValue(false)
    element.submit(submitCallbackSpy)
  })

  afterEach(function () {
    element.remove()
  })

  describe('when keying command+s', function () {
    beforeEach(function () {
      spyOn($, 'ajax')
    })

    it('attempts to save', function () {
      Mousetrap.trigger('command+s')
      expect($.ajax).toHaveBeenCalled()
    })

    describe('and save button is not visible', function () {
      it('does not save', function () {
        element.find('.js-save').hide()
        Mousetrap.trigger('command+s')
        expect($.ajax).not.toHaveBeenCalled()
      })
    })

    describe('and save button is disabled', function () {
      it('does not save', function () {
        element.find('.js-save').prop('disabled', true)
        Mousetrap.trigger('command+s')
        expect($.ajax).not.toHaveBeenCalled()
      })
    })
  })

  describe('when attempting to save multiple times before a request finishes', function () {
    it('saves only once', function () {
      spyOn($, 'ajax')
      element.find('.js-save').trigger('click')
      Mousetrap.trigger('command+s')
      Mousetrap.trigger('command+s')
      expect($.ajax.calls.count()).toEqual(1)
    })

    it('saves again afterwards', function () {
      var complete
      spyOn($, 'ajax').and.callFake(function (options) {
        complete = options.complete
      })
      Mousetrap.trigger('command+s')
      Mousetrap.trigger('command+s')
      expect($.ajax.calls.count()).toEqual(1)
      complete()
      Mousetrap.trigger('command+s')
      expect($.ajax.calls.count()).toEqual(2)
    })
  })

  describe('when clicking a save link', function () {
    // it('indicates the form is saving', function () {
    //   element.find('.js-save').trigger('click')
    //
    //   var statusMessage = element.find('.js-status-message')
    //   expect(statusMessage.text()).toBe('Saving…')
    //   expect(statusMessage.is('.workflow-message-saving')).toBe(true)
    // })

    it('posts the form using ajax', function () {
      var ajaxOptions
      spyOn($, 'ajax').and.callFake(function (options) {
        ajaxOptions = options
      })
      element.find('.js-save').trigger('click')

      expect($.ajax).toHaveBeenCalled()
      expect(ajaxOptions.type).toBe('POST')
      expect(ajaxOptions.url).toBe('some/url.json')
      expect(ajaxOptions.data).toBe('edition_test=prefilled+value&fake-file-input=')
    })
  })

  describe('when an ajax save is successful', function () {
    var timeoutTime

    beforeEach(function () {
      GOVUKAdmin.Data.editionFormDirty = true
      spyOn($, 'ajax').and.callFake(function (options) {
        options.success({ title: 'Title' })
        options.complete()
      })
      spyOn(window, 'setTimeout').and.callFake(function (fn, time) {
        timeoutTime = time
        fn()
      })
      element.find('.js-save').trigger('click')
    })

    it('says that it has saved', function () {
      var statusMessage = element.find('.js-status-message')
      expect(statusMessage.text()).toBe('Saved')
      expect(statusMessage.is('.workflow-message-saved')).toBe(true)
    })

    it('marks the form as clean', function () {
      expect(GOVUKAdmin.Data.editionFormDirty).toBe(false)
    })

    it('the save message disappears after a short while', function () {
      expect(timeoutTime).toBe(2000)
      expect(element.find('.js-status-message').is('.workflow-message-hide'))
    })

    it('triggers a success.ajaxsave.admin dom event', function () {
      var successResponse = false
      element.on('success.ajaxsave.admin', function (evt, response) {
        successResponse = response
      })
      element.find('.js-save').trigger('click')
      expect(successResponse).toEqual({ title: 'Title' })
    })
  })

  describe('when an ajax save errors with validation messages', function () {
    var timeoutTime, ajaxError, ajaxSuccess

    beforeEach(function () {
      spyOn($, 'ajax').and.callFake(function (options) {
        ajaxError = function (errors) {
          errors = errors || {}
          options.error({ responseJSON: errors })
          options.complete()
        }

        ajaxSuccess = function () {
          options.success({ title: 'Title' })
          options.complete()
        }
      })

      spyOn(window, 'setTimeout').and.callFake(function (fn, time) {
        timeoutTime = time
        fn()
      })
      element.find('.js-save').trigger('click')
    })

    it('marks the form as dirty', function () {
      GOVUKAdmin.Data.editionFormDirty = false
      ajaxError()
      expect(GOVUKAdmin.Data.editionFormDirty).toBe(true)
    })

    it('says that it couldn’t save', function () {
      ajaxError()
      var statusMessage = element.find('.js-status-message')
      expect(statusMessage.text()).toBe('We had some problems saving. Please check the form above.')
      expect(statusMessage.is('.workflow-message-error')).toBe(true)
    })

    it('the error message disappears after a short while', function () {
      ajaxError()
      expect(timeoutTime).toBe(4000)
      expect(element.find('.js-status-message').is('.workflow-message-hide'))
    })

    it('shows the error alongside the erroring field', function () {
      ajaxError({ test: ['must be changed'] })

      var parents = element.find('#edition_test').parents('.form-group')

      expect(parents.is('.has-error')).toBe(true)
      expect(parents.find('.error-block li').length).toBe(1)
      expect(parents.find('.error-block li:first').text()).toBe('must be changed')
    })

    it('includes the base error in the save dialogue', function () {
      ajaxError({ base: ['Form is wholly wrong'] })
      var statusMessage = element.find('.js-status-message')
      expect(statusMessage.text()).toBe('We had some problems saving. Form is wholly wrong.')
    })

    it('ignores validation messages for fields it does not recognise', function () {
      ajaxError({ not_a_field: ['nonsense'] })
      expect(element.find('.has-error').length).toBe(0)
    })

    it('can show multiple errors', function () {
      ajaxError({ test: ['must be changed', 'must be blue'], another: ['must rhyme'] })

      var el = element.find('#edition_test')
      var parents = el.parents('.form-group')
      expect(parents.is('.has-error')).toBe(true)
      expect(parents.find('.error-block li').length).toBe(2)
      expect(parents.find('.error-block li:first').text()).toBe('must be changed')
      expect(parents.find('.error-block li:last').text()).toBe('must be blue')

      el = element.find('#edition_another')
      parents = el.parents('.form-group')
      expect(parents.is('.has-error')).toBe(true)
      expect(parents.find('.error-block li').length).toBe(1)
      expect(parents.find('.error-block li:first').text()).toBe('must rhyme')
    })

    it('renders an error summary component which link to the correct inputs', function () {
      ajaxError({ test: ['must be changed', 'must be blue'], another: ['must rhyme'] })

      var errorSummary = element.find('#error-summary')
      var heading = errorSummary.find('h3')[0]
      var links = errorSummary.find('a')
      var error1 = links[0]
      var error2 = links[1]
      var error3 = links[2]

      expect(heading.textContent).toBe('There is a problem')
      expect(error1.hash).toBe('#edition_test')
      expect(error1.text).toBe('must be changed')
      expect(error2.hash).toBe('#edition_test')
      expect(error2.text).toBe('must be blue')
      expect(error3.hash).toBe('#edition_another')
      expect(error3.text).toBe('must rhyme')
    })

    // it('does not render errors with the message "is invalid" or where the errorKey is "parts"', function () {
    //   ajaxError({ 'test': ['must be changed', 'is invalid'], parts: ['must rhyme'] })
    //
    //   var links = element.find('#error-summary').find('a')
    //
    //   expect(links.length).toBe(1)
    // })

    it('triggers an error.ajaxsave.admin dom event', function () {
      var errorResponse = false
      element.on('errors.ajaxsave.admin', function (evt, response) {
        errorResponse = response
      })
      ajaxError({ not_a_field: ['nonsense'] })
      expect(errorResponse).toEqual({ responseJSON: { not_a_field: ['nonsense'] } })
    })

    describe('when the form is saved again', function () {
      it('removes all errors', function () {
        ajaxError({ test: ['must be changed', 'must be blue'], another: ['must rhyme'] })
        element.find('.js-save').trigger('click')

        expect(element.find('.has-error').length).toBe(0)
      })

      it('removes the error summary component if successful', function () {
        ajaxError({ test: ['must be changed', 'must be blue'], another: ['must rhyme'] })
        element.find('.js-save').trigger('click')
        ajaxSuccess()

        expect(element.find('#error-summary').length).toBe(0)
      })

      it('removes validation errors that have been completed if unsuccessful', function () {
        ajaxError({ test: ['must be changed', 'must be blue'], another: ['must rhyme'] })
        element.find('.js-save').trigger('click')
        ajaxError({ test: ['must be changed'], another: ['must rhyme'] })

        expect(element.find('#error-summary').find('a').length).toBe(2)
      })
    })
  })

  /* Cannot simulate a file input with a value, instead test this feature by proxy
     using an input which has the class 'js-no-ajax' and setting a value on it */
  describe('when submitting a form with fields that need a full page reload', function () {
    it('still indicates the form is saving', function () {
      element.find('.js-no-ajax[name="fake-file-input"]').val('has value as if file was selected')
      element.find('.js-save').trigger('click')

      var statusMessage = element.find('.js-status-message')
      expect(statusMessage.text()).toBe('Saving…')
      expect(statusMessage.is('.workflow-message-saving')).toBe(true)
    })

    it('avoids ajax if a non-ajax text input has a value', function () {
      spyOn($, 'ajax')
      element.find('.js-no-ajax[name="fake-file-input"]').val('has value as if file was selected')
      element.find('.js-save').trigger('click')

      expect($.ajax).not.toHaveBeenCalled()

      element.find('.js-no-ajax[name="fake-file-input"]').val('')
      element.find('.js-save').trigger('click')

      expect($.ajax).toHaveBeenCalled()
    })

    it('avoids ajax if a non-ajax checkbox is checked', function () {
      spyOn($, 'ajax')
      element.find('.js-no-ajax[name="remove-file-checkbox"]').attr('checked', true)
      element.find('.js-save').trigger('click')

      expect($.ajax).not.toHaveBeenCalled()
    })
  })
})
