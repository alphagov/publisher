(function(Modules) {
  "use strict";
  Modules.AssigneeSelect = function() {
    this.start = function(element) {
      element.select2({allowClear : true, dropdownAutoWidth : true});
    }
  };
})(window.GOVUKAdmin.Modules);
