(function(Modules) {
  "use strict";
  Modules.Parts = function() {
    this.start = function(element) {

      element.on('change', 'input.title', generateSlug);
      makePartsSortable();

      function generateSlug() {
        var $titleInput = $(this),
            value       = $titleInput.val(),
            $slugInput  = $titleInput.closest('.part').find('.slug');

        if ($slugInput.text() === '') {
          $slugInput.val(GovUKGuideUtils.convertToSlug(value));
        }
      }

      function makePartsSortable() {
        var accordionSelector = ".js-sort-handle",
            sortableOptions = {
              axis: "y",
              handle: accordionSelector,
              stop: function(event, ui) {
                element.find('.part').each(function (i, elem) {
                  $(elem).find('input.order').val(i + 1);
                });

                ui.item.find(accordionSelector).addClass("yellow-fade");
              }
            };

        element.sortable(sortableOptions);
      }
    }
  };
})(window.GOVUKAdmin.Modules);
