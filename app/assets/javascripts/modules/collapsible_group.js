(function(Modules) {
  "use strict";

  /* Click a link to expand or collapse all Bootstrap 3
     collapisibles within specified element

     http://getbootstrap.com/javascript/#collapse
  */
  Modules.CollapsibleGroup = function() {
    var that = this;

    that.start = function(element) {
      element.on('click', '.js-toggle-all', toggleAll);

      function toggleAll(event) {
        var action = hasOpenItems() ? 'hide' : 'show';

        element.find('.collapse').collapse(action);
        event.preventDefault();
      }

      function hasOpenItems() {
        return element.find('.collapse.in').length > 0;
      }
    }
  };

})(window.GOVUKAdmin.Modules);
