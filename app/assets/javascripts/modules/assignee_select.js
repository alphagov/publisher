(function(Modules) {
  "use strict";
  Modules.AssigneeSelect = function() {
    this.start = function(element) {
      element.select2({dropdownAutoWidth : true});
    }
  };
})(window.GOVUKAdmin.Modules);
