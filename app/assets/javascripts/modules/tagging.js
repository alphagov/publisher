(function(Modules) {
  "use strict";
  Modules.Tagging = function() {
    var that = this;
    that.start = function(element) {
      var $primaryMainstream = $('#tagging_tagging_update_form_parent');
      var $mainstreams = $('#tagging_tagging_update_form_mainstream_browse_pages');
      var $mainstreamAlertWarning = $('.mainstream.alert-warning');

      element.on('change', function() {
        element.addClass('interacted');

        var mainstreams = $mainstreams.val() || [];
        var primaryMainstream = $primaryMainstream.val() || [];

        if (primaryMainstream.length != 0) {
          if (mainstreams.length == 0 || (mainstreams.indexOf(primaryMainstream) == -1 )) {
            $mainstreamAlertWarning.removeClass('hidden');
          }
          else {
            $mainstreamAlertWarning.addClass('hidden');
          }
        }
        else if (mainstreams.length > primaryMainstream.length && $primaryMainstream.hasClass('interacted')) {
          $mainstreamAlertWarning.removeClass('hidden');
        }

      })
    }
  };
})(window.GOVUKAdmin.Modules);
