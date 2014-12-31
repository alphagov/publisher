(function(Modules) {
  "use strict";
  Modules.TabSwitcher = function() {
    this.start = function(element) {
      element.on('show.bs.tab', function(e) {
        if (window.history && window.history.replaceState) {
          window.history.replaceState(null, null, $(e.target).attr('href'));
        }
      });
    }
  };
})(window.GOVUKAdmin.Modules);
