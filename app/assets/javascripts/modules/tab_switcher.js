(function(Modules) {
  "use strict";
  Modules.TabSwitcher = function() {
    this.start = function(element) {
      element.on('show.bs.tab', function(e) {
        if (window.history && window.history.replaceState) {
          window.history.replaceState(null, null, $(e.target).attr('href'));

          // Track tab switch as pageview
          // https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
          if (typeof ga === "function") {
            ga('send', 'pageview');
          }
        }

        // Shim Boostrap tabs, which are only capabable of removing
        // the active class from a tab-pane that is a direct child of
        // the tab-content container. See:
        // https://github.com/twbs/bootstrap/blob/master/js/tab.js#L52
        //
        // Works in conjunction with:
        // https://github.com/alphagov/publisher/blob/master/app/assets/stylesheets/bootstrap_and_overrides.css.scss#L98-L110
        resetAllTabs();
      });

      function resetAllTabs() {
        element.find('.tab-pane').each(function() {
          $(this).removeClass('active');
        });
      }

    }
  };
})(window.GOVUKAdmin.Modules);
