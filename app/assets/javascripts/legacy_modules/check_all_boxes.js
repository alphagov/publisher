(function (Modules) {
  'use strict'

  /* Click a check all checkbox to select or unselect all
     other checkboxes within the module */
  Modules.CheckAllBoxes = function () {
    const that = this

    that.start = function (element) {
      element.on('click', '.js-check-all', toggleAllCheckboxes)

      function toggleAllCheckboxes (event) {
        const $target = $(event.target)
        element.find(':checkbox:enabled').each(function () {
          $(this).prop('checked', $target.is(':checked'))
        })
      }
    }
  }
})(window.GOVUKAdmin.Modules)
