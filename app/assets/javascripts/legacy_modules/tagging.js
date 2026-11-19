(function (Modules) {
  'use strict'
  Modules.Tagging = function () {
    const that = this
    that.start = function (element) {
      const $primaryMainstream = $('#tagging_tagging_update_form_parent')
      const $mainstreams = $('#tagging_tagging_update_form_mainstream_browse_pages')
      const $mainstreamAlertWarning = $('.mainstream.alert-warning')

      element.on('change', function () {
        element.addClass('interacted')

        const mainstreams = $mainstreams.val() || []
        const primaryMainstream = $primaryMainstream.val() || []

        if (primaryMainstream.length !== 0) {
          if (mainstreams.length === 0 || (mainstreams.indexOf(primaryMainstream) === -1)) {
            $mainstreamAlertWarning.removeClass('hidden')
          } else {
            $mainstreamAlertWarning.addClass('hidden')
          }
        } else if (mainstreams.length > primaryMainstream.length && $primaryMainstream.hasClass('interacted')) {
          $mainstreamAlertWarning.removeClass('hidden')
        }
      })
    }
  }
})(window.GOVUKAdmin.Modules)
