(function(Modules) {
  "use strict";
  Modules.Parts = function() {
    this.start = function(element) {

      makePartsSortable();

      function makePartsSortable() {
        var accordionSelector = ".js-sort-handle",
            sortableOptions = {
              axis: "y",
              handle: accordionSelector,
              stop: function(event, ui) {
                element.find('.part').each(function (i, elem) {
                  $(elem).find('input.order').val(i + 1);
                  ui.item.find(accordionSelector).addClass("yellow-fade");
                });
              }
            };

        element.sortable(sortableOptions);
      }
    }
  };
})(window.GOVUKAdmin.Modules);
