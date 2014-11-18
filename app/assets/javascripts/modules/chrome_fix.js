(function(Modules) {
  "use strict";
  Modules.ChromeFix = function() {
    this.start = function(element) {
      try {
        var chromeVersion = window.navigator.appVersion.match(/Chrome\/(\d+)\./);
        if (chromeVersion && parseInt(chromeVersion[1],10) < 39) {
          window.scrollTo(0,0);
        }
      } catch (ex) {
        // Ignore browser exceptions when window.navigator check fails
      }
    }
  };
})(window.GOVUKAdmin.Modules);
