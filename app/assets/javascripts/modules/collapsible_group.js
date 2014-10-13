(function(Modules) {
  "use strict";

  /* Click a link to expand or collapse all Bootstrap 3
     collapisibles within specified element

     http://getbootstrap.com/javascript/#collapse
  */
  Modules.CollapsibleGroup = function() {
    var that = this;

    that.start = function(element) {
      element.on('click', '.js-expand-all', expandAll);
      element.on('click', '.js-collapse-all', collapseAll);

      function expandAll(event) {
        element.find('.collapse').collapse('show');
        event.preventDefault();
      }

      function collapseAll(event) {
        element.find('.collapse').collapse('hide');
        event.preventDefault();
      }
    }
  };

})(window.GOVUKAdmin.Modules);
