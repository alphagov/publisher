describe('An ajax save module', function() {
  "use strict";

  var ajaxSave,
      element;

  beforeEach(function() {

    element = $('<form action="some/url">\
      <div class="js-status-message"></div>\
      <div id="edition_test_input">\
        <input type="text" name="test" value="prefilled value">\
      </div>\
      <div id="edition_another_input">\
        <input type="text" name="another" value="another value">\
      </div>\
      <input class="js-no-ajax" type="text" name="fake-file-input">\
      <input class="js-no-ajax" type="checkbox" name="remove-file-checkbox" value="1">\
      <input type="submit" class="js-save" value="Save">\
    </form>');

    $('body').append(element);
    ajaxSave = new GOVUKAdmin.Modules.AjaxSave();
    ajaxSave.start(element);
  });

  afterEach(function() {
    element.remove();
  });

  describe('when keying command+s', function() {
    it('attempts to save', function() {
      spyOn($, 'ajax');
      Mousetrap.trigger('command+s');
      expect($.ajax).toHaveBeenCalled();
    });
  });

  describe('when attempting to save multiple times before a request finishes', function() {
    it('saves only once', function() {
      spyOn($, 'ajax');
      element.find('.js-save').trigger('click');
      Mousetrap.trigger('command+s');
      Mousetrap.trigger('command+s');
      expect($.ajax.calls.count()).toEqual(1);
    });

    it('saves again afterwards', function() {
      var complete;
      spyOn($, 'ajax').and.callFake(function(options) {
        complete = options.complete;
      });
      Mousetrap.trigger('command+s');
      Mousetrap.trigger('command+s');
      expect($.ajax.calls.count()).toEqual(1);
      complete();
      Mousetrap.trigger('command+s');
      expect($.ajax.calls.count()).toEqual(2);
    });
  });

  describe('when clicking a save link', function() {
    it('indicates the form is saving', function() {
      element.find('.js-save').trigger('click');

      var statusMessage = element.find('.js-status-message');
      expect(statusMessage.text()).toBe('Saving…');
      expect(statusMessage.is('.workflow-message-saving')).toBe(true);
    });

    it('posts the form using ajax', function() {
      var ajaxOptions;
      spyOn($, 'ajax').and.callFake(function(options) {
        ajaxOptions = options;
      });
      element.find('.js-save').trigger('click');

      expect($.ajax).toHaveBeenCalled();
      expect(ajaxOptions.type).toBe('POST');
      expect(ajaxOptions.url).toBe('some/url.json');
      expect(ajaxOptions.data).toBe('test=prefilled+value&another=another+value&fake-file-input=');
    });
  });

  describe('when an ajax save is successful', function() {
    var timeoutTime;

    beforeEach(function() {
      GOVUKAdmin.Data.editionFormDirty = true;
      spyOn($, 'ajax').and.callFake(function(options) {
        options.success({title: 'Title'});
        options.complete();
      });
      spyOn(window, 'setTimeout').and.callFake(function(fn, time) {
        timeoutTime = time;
        fn();
      });
      element.find('.js-save').trigger('click');
    });

    it('says that it has saved', function() {
      var statusMessage = element.find('.js-status-message');
      expect(statusMessage.text()).toBe('Saved');
      expect(statusMessage.is('.workflow-message-saved')).toBe(true);
    });

    it('marks the form as clean', function() {
      expect(GOVUKAdmin.Data.editionFormDirty).toBe(false);
    });

    it('the save message disappears after a short while', function() {
      expect(timeoutTime).toBe(2000);
      expect(element.find('.js-status-message').is('.workflow-message-hide'));
    });

    it('triggers a success.ajaxsave.admin dom event', function() {
      var successResponse = false;
      element.on('success.ajaxsave.admin', function(evt, response) {
        successResponse = response;
      });
      element.find('.js-save').trigger('click');
      expect(successResponse).toEqual({title: 'Title'});
    });
  });

  describe('when an ajax save errors with validation messages', function() {
    var timeoutTime, ajaxError, ajaxSuccess;

    beforeEach(function() {
      spyOn($, 'ajax').and.callFake(function(options) {
        ajaxError = function(errors) {
          errors = errors || {};
          options.error({responseJSON: errors});
          options.complete();
        };

        ajaxSuccess = options.success;
      });
      spyOn(window, 'setTimeout').and.callFake(function(fn, time) {
        timeoutTime = time;
        fn();
      });
      element.find('.js-save').trigger('click');
    });

    it('marks the form as dirty', function() {
      GOVUKAdmin.Data.editionFormDirty = false;
      ajaxError();
      expect(GOVUKAdmin.Data.editionFormDirty).toBe(true);
    });

    it('says that it couldn’t save', function() {
      ajaxError();
      var statusMessage = element.find('.js-status-message');
      expect(statusMessage.text()).toBe('We had some problems saving. Please check the form above.');
      expect(statusMessage.is('.workflow-message-error')).toBe(true);
    });

    it('the error message disappears after a short while', function() {
      ajaxError();
      expect(timeoutTime).toBe(4000);
      expect(element.find('.js-status-message').is('.workflow-message-hide'));
    });

    it('shows the error alongside the erroring field', function() {
      ajaxError({test: ['must be changed']});
      expect(element.find('#edition_test_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_test_input ul li').length).toBe(1);
      expect(element.find('#edition_test_input ul li:first').text()).toBe('must be changed');
    });

    it('includes the base error in the save dialogue', function() {
      ajaxError({base: ['Form is wholly wrong']});
      var statusMessage = element.find('.js-status-message');
      expect(statusMessage.text()).toBe('We had some problems saving. Form is wholly wrong.');
    });

    it('ignores validation messages for fields it does not recognise', function() {
      ajaxError({not_a_field: ['nonsense']});
      expect(element.find('.has-error').length).toBe(0);
      expect(element.find('.js-error').length).toBe(0);
    });

    it('can show multiple errors', function() {
      ajaxError({test: ['must be changed', 'must be blue'], another: ['must rhyme']});

      expect(element.find('#edition_test_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_test_input ul li').length).toBe(2);
      expect(element.find('#edition_test_input ul li:first').text()).toBe('must be changed');
      expect(element.find('#edition_test_input ul li:last').text()).toBe('must be blue');

      expect(element.find('#edition_another_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_another_input ul li').length).toBe(1);
      expect(element.find('#edition_another_input ul li:first').text()).toBe('must rhyme');
    });

    it('triggers an error.ajaxsave.admin dom event', function() {
      var errorResponse = false;
      element.on('error.ajaxsave.admin', function(evt, response) {
        errorResponse = response;
      });
      ajaxError({not_a_field: ['nonsense']});
      expect(errorResponse).toEqual({responseJSON: {not_a_field: ['nonsense']}});
    });

    describe('when the form is saved again', function() {
      it('removes all errors', function() {
        ajaxError({test: ['must be changed', 'must be blue'], another: ['must rhyme']});
        element.find('.js-save').trigger('click');

        expect(element.find('.has-error').length).toBe(0);
        expect(element.find('.js-error').length).toBe(0);
      });
    });

  });

  /* Cannot simulate a file input with a value, instead test this feature by proxy
     using an input which has the class 'js-no-ajax' and setting a value on it */
  describe('when submitting a form with fields that need a full page reload', function() {

    it('still indicates the form is saving', function() {
      element.find('.js-no-ajax[name="fake-file-input"]').val('has value as if file was selected');
      element.find('.js-save').trigger('click');

      var statusMessage = element.find('.js-status-message');
      expect(statusMessage.text()).toBe('Saving…');
      expect(statusMessage.is('.workflow-message-saving')).toBe(true);
    });

    it('avoids ajax if a non-ajax text input has a value', function() {
      var ajaxOptions;
      spyOn($, 'ajax');
      element.find('.js-no-ajax[name="fake-file-input"]').val('has value as if file was selected');
      element.find('.js-save').trigger('click');

      expect($.ajax).not.toHaveBeenCalled();

      element.find('.js-no-ajax[name="fake-file-input"]').val('');
      element.find('.js-save').trigger('click');

      expect($.ajax).toHaveBeenCalled();
    });

    it('avoids ajax if a non-ajax checkbox is checked', function() {
      var ajaxOptions;
      spyOn($, 'ajax');
      element.find('.js-no-ajax[name="remove-file-checkbox"]').attr('checked', true);
      element.find('.js-save').trigger('click');

      expect($.ajax).not.toHaveBeenCalled();
    });
  });

});
