/* globals GovUKGuideUtils */

(function (Modules) {
  'use strict'
  Modules.Parts = function () {
    this.start = function (element) {
      element.on('change', 'input.title', generateSlug)
      element.on('nested:fieldAdded:parts', addPasteHtmlToGovspeak)
      element.on('nested:fieldAdded:parts', updatePartOrders)
      element.on('nested:fieldAdded:parts', removeValidationMessages)

      makePartsSortable()

      function generateSlug () {
        const $titleInput = $(this)
        const value = $titleInput.val()
        const $slugInput = $titleInput.closest('.part').find('.slug')

        if ($slugInput.val() === '' || $slugInput.data('accepts-generated-value')) {
          $slugInput.data('accepts-generated-value', true)
          $slugInput.val(GovUKGuideUtils.convertToSlug(value))
          $slugInput.addClass('yellow-fade')

          setTimeout(function () {
            $slugInput.removeClass('yellow-fade')
          }, 2000)
        }
      }

      function addPasteHtmlToGovspeak () {
        const input = element.find('.body').slice(-1)
        const pasteHtmlToGovspeak = new GOVUKAdmin.Modules.PasteHtmlToGovspeak()
        pasteHtmlToGovspeak.start(input)
      }

      function makePartsSortable () {
        const accordionSelector = '.js-sort-handle'
        const sortableOptions = {
          axis: 'y',
          handle: accordionSelector,
          stop: function (event, ui) {
            updatePartOrders()
            ui.item.find(accordionSelector).addClass('yellow-fade')
          }
        }

        element.sortable(sortableOptions)
      }

      function updatePartOrders () {
        element.find('.part').each(function (i, elem) {
          $(elem).find('input.order').val(i + 1)
        })
      }

      function removeValidationMessages (evt) {
        const $part = $(evt.target)

        $part.find('.error, .has-error').removeClass('error').removeClass('has-error')
        $part.find('.error-block').empty()
      }
    }
  }
})(window.GOVUKAdmin.Modules)
