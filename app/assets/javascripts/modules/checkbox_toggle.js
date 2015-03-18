(function(Modules) {
  "use strict";

  Modules.CheckboxToggle = function() {

    var that = this;

    that.start = function(element) {
      element.on('change', '.js-checkbox-toggle', toggle);

      function toggle(event) {
        var isCheckboxChecked = element.find('.js-checkbox-toggle').is(':checked');
        element.find('.js-checkbox-toggle-target').toggle(isCheckboxChecked);
      }
      toggle();
    };
  };

})(window.GOVUKAdmin.Modules);
