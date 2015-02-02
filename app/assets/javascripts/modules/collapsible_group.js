(function(Modules) {
  "use strict";

  /* Click a link to expand or collapse all Bootstrap 3
     collapsibles within specified element

     http://getbootstrap.com/javascript/#collapse
  */
  Modules.CollapsibleGroup = function() {
    var that = this;

    that.start = function(element) {

      var collapseText = element.data('collapse-text'),
          expandText = element.data('expand-text'),
          $links = element.find('.js-toggle-all');

      element.on('click', '.js-toggle-all', toggleAll);
      element.on('shown.bs.collapse hidden.bs.collapse nested:fieldRemoved nested:fieldAdded', updateLinkText);

      function toggleAll(event) {
        var action = hasOpenItems() ? 'hide' : 'show';

        element.find('.collapse').collapse(action);
        event.preventDefault();
      }

      function hasOpenItems() {
        return element.find('.collapse.in:visible').length > 0;
      }

      function updateLinkText() {
        $links.text(hasOpenItems() ? collapseText : expandText);
      }

    }
  };

})(window.GOVUKAdmin.Modules);
