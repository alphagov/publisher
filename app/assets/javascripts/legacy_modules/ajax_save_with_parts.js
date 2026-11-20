(function (Modules) {
  'use strict'
  Modules.AjaxSaveWithParts = function () {
    this.start = function (element) {
      const ajaxSave = new GOVUKAdmin.Modules.AjaxSave()

      element.on('success.ajaxsave.admin', success)
      element.on('errors.ajaxsave.admin', error)
      ajaxSave.start(element)

      function success (evt, response) {
        const parts = response.parts || response.variants
        if (parts) {
          for (let i = 0, l = parts.length; i < l; i++) {
            updatePart(parts[i])
          }
        }
        removeDeletedParts()
      }

      function error (evt, response) {
        const responseJSON = response.responseJSON
        const partErrors = typeof responseJSON === 'object' && (responseJSON.parts || responseJSON.variants)
        if (partErrors) {
          $.each(partErrors[0], showPartErrors)
        }
      }

      function removeDeletedParts () {
        const deletedParts = $("[id*='__destroy'][value='1']")
        deletedParts.parents('.fields').remove()
      }

      function showPartErrors (partKey, partErrors) {
        const partKeyParts = partKey.split(':')
        const id = partKeyParts[0]
        const order = partKeyParts[1]
        const $partContainer = identifyPartContainer(id, order)

        $partContainer.find('.collapse').collapse('show')
        $.each(partErrors, function (fieldKey, messages) {
          const $errorElement = $partContainer.find('[id*=' + fieldKey + '_input]')

          $errorElement.addClass('has-error')
          const list = $errorElement.find('.error-block')
          for (let j = 0, m = messages.length; j < m; j++) {
            list.append('<li>' + messages[j] + '</li>')
            const elementId = '#' + $errorElement.find('input')[0].id
            appendPartErrorsToErrorSummaryComponent(elementId, messages[j])
          }
        })
      }

      function appendPartErrorsToErrorSummaryComponent (elementId, message) {
        const ul = document.getElementById('error-summary').childNodes[1]
        const list = document.createElement('li')
        const errorLink = document.createElement('a')
        errorLink.href = elementId
        errorLink.innerText = message
        ul.append(list)
        list.append(errorLink)
      }

      function updatePart (part) {
        const partId = part.id
        const $partContainer = identifyPartContainer(partId, part.order)
        const $hiddenInputId = $partContainer.find('input[value="' + partId + '"]')

        $partContainer.find('.js-part-title').text(part.title)
        $partContainer.find('.js-part-toggle-target').attr('id', part.slug)
        $partContainer.find('.js-part-toggle').attr('href', '#' + part.slug)

        if ($hiddenInputId.length === 0) {
          generateHiddenIdInput($partContainer, partId)
        }
      }

      function identifyPartContainer (id, order) {
        const $hiddenIdInput = element.find('input[value="' + id + '"]')
        let $order

        if ($hiddenIdInput.length > 0) {
          return $hiddenIdInput.parents('.fields')
        } else {
          $order = element.find('input.order').filter(function () {
            return this.value == order // eslint-disable-line eqeqeq
          })

          return $order.parents('.fields')
        }
      }

      /* To prevent parts being added multiple times, once added and saved
         they must have a hidden element that contains their server
         generated ID */
      function generateHiddenIdInput ($partContainer, id) {
        const $hiddenInputId = $('<input type="hidden">')
        const $titleInput = $partContainer.find('input.title')
        const namePrefix = $titleInput.attr('name').replace(/\[title\]/, '')
        const idPrefix = $titleInput.attr('id').replace(/_title/, '')

        $hiddenInputId.attr('value', id)
        $hiddenInputId.attr('id', idPrefix + '_id')
        $hiddenInputId.attr('name', namePrefix + '[id]')

        /* <input
              id="edition_parts_attributes_123456_id"
              name="edition[parts_attributes][123456][id]"
              type="hidden"
              value="54b8d0f7759b7477d5000011"> */
        $partContainer.append($hiddenInputId)
      }
    }
  }
})(window.GOVUKAdmin.Modules)
