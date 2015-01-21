(function(Modules) {
  "use strict";
  Modules.AjaxSave = function() {
    this.start = function(element) {
      var url = element.attr('action') + '.json',
          message = element.find('.js-status-message'),
          hideTimeout;

      GOVUKAdmin.Data = GOVUKAdmin.Data || {};
      element.on('click', '.js-save', save);
      Mousetrap.bind(['command+s', 'ctrl+s'], save);

      function save(evt) {
        saving();

        if (allFieldsCanBeSavedWithAjax()) {
          if (typeof evt.preventDefault === "function") {
            evt.preventDefault();
          }
          postForm();
        }
      }

      function postForm() {
        $.ajax({
          url : url,
          type : 'POST',
          data : element.serialize(),
          success : success,
          error: error
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

        element.trigger('success.ajaxsave.admin', response);
      }

      function error(response) {
        if (typeof response.responseJSON === "object") {
          showErrors(response.responseJSON);
        }
        message.addClass('workflow-message-error').removeClass('workflow-message-saving');
        message.text('Couldn’t save');
        hideTimeout = setTimeout(hide, 2000);

        // Save errored, form still has unsaved changes
        GOVUKAdmin.Data.editionFormDirty = true;

        element.trigger('error.ajaxsave.admin', response);
      }

      function showErrors(errors) {
        var keys = Object.keys(errors);

        for(var i = 0, l = keys.length; i < l; i++) {

          var errorElement = element.find('#edition_' + keys[i] + '_input'),
              errorMessages = errors[keys[i]],
              $list = $('<ul class="help-block js-error"></ul>');

          errorElement.addClass('has-error');

          for(var j = 0, m = errorMessages.length; j < m; j++) {
            $list.append('<li>' + errorMessages[j] + '</li>');
          }

          errorElement.append($list);
        }
      }

      function hideErrors() {
        element.find('.js-error').remove();
        element.find('.has-error').removeClass('has-error');
      }

      function saving() {
        reset();
        message.addClass('workflow-message-saving');
        message.text('Saving…');

        // Save attempt, form is no longer dirty
        GOVUKAdmin.Data.editionFormDirty = false;
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
