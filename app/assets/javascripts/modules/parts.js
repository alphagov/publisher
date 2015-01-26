(function(Modules) {
  "use strict";
  Modules.Parts = function() {
    this.start = function(element) {

      element.on('change', 'input.title', generateSlug);
      element.on('nested:fieldAdded:parts', updatePartOrders);
      makePartsSortable();

      function generateSlug() {
        var $titleInput = $(this),
            value       = $titleInput.val(),
            $slugInput  = $titleInput.closest('.part').find('.slug');

        if ($slugInput.val() === '' || $slugInput.data('accepts-generated-value')) {
          $slugInput.data('accepts-generated-value', true);
          $slugInput.val(GovUKGuideUtils.convertToSlug(value));
          $slugInput.addClass("yellow-fade");

          setTimeout(function() {
            $slugInput.removeClass("yellow-fade");
          }, 2000)
        }
      }

      function makePartsSortable() {
        var accordionSelector = ".js-sort-handle",
            sortableOptions = {
              axis: "y",
              handle: accordionSelector,
              stop: function(event, ui) {
                updatePartOrders();
                ui.item.find(accordionSelector).addClass("yellow-fade");
              }
            };

        element.sortable(sortableOptions);
      }

      function updatePartOrders() {
        element.find('.part').each(function (i, elem) {
          $(elem).find('input.order').val(i + 1);
        });
      }
    }
  };
})(window.GOVUKAdmin.Modules);
