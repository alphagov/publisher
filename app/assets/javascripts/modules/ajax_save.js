(function(Modules) {
  "use strict";
  Modules.AjaxSave = function() {
    this.start = function(element) {
      var url = element.attr('action') + '.json',
          message = element.find('.js-status-message'),
          hideTimeout;

      element.on('click', '.js-save', save);

      function save(evt) {
        evt.preventDefault();
        saving();

        $.ajax({
          url : url,
          type : 'POST',
          data : element.serialize(),
          success : success,
          error: error
        });
      }

      function success(response) {
        hideErrors();
        message.addClass('workflow-message-saved').removeClass('workflow-message-saving');
        message.text('Saved');
        hideTimeout = setTimeout(hide, 2000);
      }

      function error(response) {
        if (typeof response.responseJSON === "object") {
          showErrors(response.responseJSON);
        }
        message.addClass('workflow-message-error').removeClass('workflow-message-saving');
        message.text('Couldn’t save');
        hideTimeout = setTimeout(hide, 2000);
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
