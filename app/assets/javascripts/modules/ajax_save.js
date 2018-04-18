(function(Modules) {
  "use strict";
  Modules.AjaxSave = function() {
    this.start = function(element) {
      var url = element.attr('action') + '.json',
          message = element.find('.js-status-message'),
          requestRunning = false,
          hideTimeout;

      GOVUKAdmin.Data = GOVUKAdmin.Data || {};
      element.on('click', '.js-save', save);
      Mousetrap.bindGlobal(['command+s', 'ctrl+s'], saveViaKeyboard);

      function saveViaKeyboard(evt) {
        if (element.find('.js-save:visible:enabled').length > 0) {
          save(evt);
        }
      }

      function save(evt) {
        var canPreventDefault = typeof evt.preventDefault === "function";

        if (requestRunning) {
          if (canPreventDefault) {
            evt.preventDefault();
          }
          return;
        }

        saving();

        if (allFieldsCanBeSavedWithAjax()) {
          if (canPreventDefault) {
            evt.preventDefault();
          }
          postForm();
        }

        // if default not prevented, event bubbles up and form is
        // intentionally submitted without ajax
      }

      function postForm() {
        requestRunning = true;

        $.ajax({
          url : url,
          type : 'POST',
          data : element.serialize(),
          success : success,
          error: error,
          complete: function() {
            requestRunning = false;
          }
        });
      }

      function allFieldsCanBeSavedWithAjax() {
        var ok = true;
        element.find('.js-no-ajax, input[type="file"]').each(function() {
          var $input = $(this),
              value = $input.val();

          if ($input.is(':checkbox')) {
            if ($input.is(':checked')) {
              ok = false;
            }
          } else {
            if (value && value.length > 0) {
              ok = false;
            }
          }
        });

        return ok;
      }

      function success(response) {
        hideErrors();
        message.addClass('workflow-message-saved').removeClass('workflow-message-saving');
        message.text('Saved');
        hideTimeout = setTimeout(hide, 2000);

        // Save successful, form is no longer dirty
        GOVUKAdmin.Data.editionFormDirty = false;
        window.GOVUKAdmin.trackEvent('ajax-save', 'success');

        element.trigger('success.ajaxsave.admin', response);
      }

      function error(response, textStatus, errorThrown) {
        var responseJSON = response.responseJSON,
            messageAddendum = "Please check the form above.";

        if (typeof responseJSON === "object") {
          showErrors(responseJSON);
          trackErrors(JSON.stringify(responseJSON))

          if (typeof responseJSON.base === "object") {
            messageAddendum = '<strong>' + responseJSON.base[0] + '</strong>.';
          }
        } else {
          window.GOVUKAdmin.trackEvent('ajax-save', 'error', { value: textStatus + ': ' + errorThrown });
        }

        message.addClass('workflow-message-error').removeClass('workflow-message-saving');
        message.html('We had some problems saving. ' + messageAddendum);
        hideTimeout = setTimeout(hide, 4000);

        // Save errored, form still has unsaved changes
        GOVUKAdmin.Data.editionFormDirty = true;

        element.trigger('error.ajaxsave.admin', response);
      }

      function showErrors(errors) {
        $.each(errors, function(errorKey, errorMessages) {
          var errorElement = element.find('#edition_' + errorKey + '_input'),
              $list = $('<ul class="help-block js-error"></ul>');

          errorElement.addClass('has-error');
          for(var j = 0, m = errorMessages.length; j < m; j++) {
            $list.append('<li>' + errorMessages[j] + '</li>');
          }

          errorElement.append($list);
        });
      }

      function trackErrors(label) {
        // Normalise parts errors, eg "54c0db08e5274000cc:10": to "part":
        label = label.replace(/"[0-9a-fA-F]+:\d{1,2}":/g, '"part":');
        window.GOVUKAdmin.trackEvent('ajax-save-error', label);
      }

      function hideErrors() {
        element.find('.js-error').remove();
        element.find('.has-error').removeClass('has-error');
      }

      function saving() {
        reset();
        message.addClass('workflow-message-saving');
        message.text('Saving…');
      }

      function hide() {
        message.addClass('workflow-message-hide');
      }

      function reset() {
        hideErrors();
        clearTimeout(hideTimeout);
        message.removeClass(function (index, css) {
          return (css.match(/(^|\s)workflow-message-\S+/g) || []).join(' ');
        });
      }
    }
  };
})(window.GOVUKAdmin.Modules);
