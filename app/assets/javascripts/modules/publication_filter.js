(function(Modules) {
  "use strict";
  Modules.PublicationFilter = function() {
    this.start = function(element) {
      var $userFilter = element.find('.js-user-filter');
      $userFilter.select2({dropdownAutoWidth : true});
    }
  };
})(window.GOVUKAdmin.Modules);
