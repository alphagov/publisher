(function(Modules) {
  "use strict";
  Modules.AjaxSaveWithParts = function() {
    this.start = function(element) {
      var ajaxSave = new GOVUKAdmin.Modules.AjaxSave();

      element.on('success.ajaxsave.admin', success);
      //element.on('error.ajaxsave.admin', error);
      ajaxSave.start(element);

      function success(evt, response) {
        var parts = response.parts;
        if (parts) {
          for (var i = 0, l = parts.length; i < l; i++) {
            updatePart(parts[i]);
          }
        }
      }

      function updatePart(part) {
        var $partContainer = identifyPartContainer(part),
            $hiddenInputId = $partContainer.find('input[value="'+part._id+'"]');

        $partContainer.find('.js-part-title').text(part.title);
        $partContainer.find('.js-part-toggle-target').attr('id', part.slug);
        $partContainer.find('.js-part-toggle').attr('href', '#' + part.slug);

        if ($hiddenInputId.length == 0) {
          generateHiddenIdInput($partContainer, part._id);
        }
      }

      function identifyPartContainer(part) {
        var $hiddenIdInput = element.find('input[value="'+part._id+'"]'),
            $title;

        if ($hiddenIdInput.length > 0) {
          return $hiddenIdInput.parents('.fields');
        } else {
          $title = element.find('input.title').filter(function() {
            return this.value == part.title
          });

          return $title.parents('.fields');
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
