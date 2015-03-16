(function(Modules) {
  "use strict";

  Modules.CheckboxToggle = function() {

    var that = this;

    that.start = function(element) {
      element.on('change', '.js-checkbox-toggle', toggle);

      function toggle(event) {
        element.find('.js-checkbox-toggle-target').toggle(element.find('.js-checkbox-toggle').is(':checked'));
      }
      toggle();
    };
  };

})(window.GOVUKAdmin.Modules);
