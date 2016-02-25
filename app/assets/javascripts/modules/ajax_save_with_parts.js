(function(Modules) {
  "use strict";
  Modules.AjaxSaveWithParts = function() {
    this.start = function(element) {
      var ajaxSave = new GOVUKAdmin.Modules.AjaxSave();

      element.on('success.ajaxsave.admin', success);
      element.on('error.ajaxsave.admin', error);
      ajaxSave.start(element);

      function success(evt, response) {
        var parts = response.parts;
        if (parts) {
          for (var i = 0, l = parts.length; i < l; i++) {
            updatePart(parts[i]);
          }
        }
      }

      function error(evt, response) {
        var responseJSON = response.responseJSON,
            partErrors = typeof responseJSON === "object" && responseJSON.parts;

        if (partErrors) {
          $.each(partErrors[0], showPartErrors);
        }
      }

      function showPartErrors(partKey, partErrors) {
        var partKeyParts = partKey.split(':'),
            id = partKeyParts[0],
            order = partKeyParts[1],
            $partContainer = identifyPartContainer(id, order);

        $partContainer.find('.collapse').collapse('show');
        $.each(partErrors, function(fieldKey, messages) {
          var $errorElement = $partContainer.find('[id*=' + fieldKey + '_input]'),
              $list = $('<ul class="help-block js-error"></ul>');

          $errorElement.addClass('has-error');
          for(var j = 0, m = messages.length; j < m; j++) {
            $list.append('<li>' + messages[j] + '</li>');
          }
          $errorElement.append($list);
        });
      }

      function updatePart(part) {
        var partId = part._id.$oid;
        var $partContainer = identifyPartContainer(partId, part.order),
            $hiddenInputId = $partContainer.find('input[value="'+partId+'"]');

        $partContainer.find('.js-part-title').text(part.title);
        $partContainer.find('.js-part-toggle-target').attr('id', part.slug);
        $partContainer.find('.js-part-toggle').attr('href', '#' + part.slug);

        if ($hiddenInputId.length == 0) {
          generateHiddenIdInput($partContainer, partId);
        }
      }

      function identifyPartContainer(id, order) {
        var $hiddenIdInput = element.find('input[value="' + id + '"]'),
            $order;

        if ($hiddenIdInput.length > 0) {
          return $hiddenIdInput.parents('.fields');
        } else {
          $order = element.find('input.order').filter(function() {
            return this.value == order;
          });

          return $order.parents('.fields');
        }
      }

      /* To prevent parts being added multiple times, once added and saved
         they must have a hidden element that contains their server
         generated ID */
      function generateHiddenIdInput($partContainer, id) {
        var $hiddenInputId = $('<input type="hidden">'),
            $titleInput = $partContainer.find('input.title'),
            namePrefix = $titleInput.attr('name').replace(/\[title\]/,''),
            idPrefix = $titleInput.attr('id').replace(/_title/,'');

        $hiddenInputId.attr('value', id);
        $hiddenInputId.attr('id', idPrefix + '_id');
        $hiddenInputId.attr('name', namePrefix + '[id]');

        /* <input
              id="edition_parts_attributes_123456_id"
              name="edition[parts_attributes][123456][id]"
              type="hidden"
              value="54b8d0f7759b7477d5000011"> */
        $partContainer.append($hiddenInputId);
      }

    }
  };
})(window.GOVUKAdmin.Modules);
