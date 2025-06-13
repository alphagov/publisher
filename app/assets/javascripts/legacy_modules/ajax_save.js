/* globals Mousetrap */

(function (Modules) {
  'use strict'
  Modules.AjaxSave = function () {
    this.start = function (element) {
      var url = element.attr('action') + '.json'
      var message = element.find('.js-status-message')
      var requestRunning = false
      var hideTimeout

      GOVUKAdmin.Data = GOVUKAdmin.Data || {}
      element.on('click', '.js-save', save)
      element.on('success.ajaxsave.admin', partsSuccess)
      element.on('errors.ajaxsave.admin', partsError)

      Mousetrap.bindGlobal(['command+s', 'ctrl+s'], saveViaKeyboard)

      function saveViaKeyboard (evt) {
        if (element.find('.js-save:visible:enabled').length > 0) {
          save(evt)
        }
      }

      function save (evt) {
        var canPreventDefault = typeof evt.preventDefault === 'function'

        if (requestRunning) {
          if (canPreventDefault) {
            evt.preventDefault()
          }
          return
        }

        saving()

        if (allFieldsCanBeSavedWithAjax()) {
          if (canPreventDefault) {
            evt.preventDefault()
          }
          postForm()
        }

        // if default not prevented, event bubbles up and form is
        // intentionally submitted without ajax
      }

      function postForm () {
        requestRunning = true

        $.ajax({
          url: url,
          type: 'POST',
          data: element.serialize(),
          success: success,
          error: error,
          complete: function () {
            requestRunning = false
          }
        })
      }

      function allFieldsCanBeSavedWithAjax () {
        var ok = true
        element.find('.js-no-ajax, input[type="file"]').each(function () {
          var $input = $(this)
          var value = $input.val()

          if ($input.is(':checkbox')) {
            if ($input.is(':checked')) {
              ok = false
            }
          } else {
            if (value && value.length > 0) {
              ok = false
            }
          }
        })

        return ok
      }

      function success (response) {
        hideErrors()
        message.addClass('workflow-message-saved').removeClass('workflow-message-saving')
        message.text('Saved')
        hideTimeout = setTimeout(hide, 2000)

        // Save successful, form is no longer dirty
        GOVUKAdmin.Data.editionFormDirty = false

        element.trigger('success.ajaxsave.admin', response)
      }

      function error (response, textStatus, errorThrown) {
        var responseJSON = response.responseJSON
        var messageAddendum = 'Please check the form above.'

        if (typeof responseJSON === 'object') {
          showErrors(responseJSON)
          destroyErrorSummaryComponent()
          displayErrorSummaryComponent(responseJSON)

          if (typeof responseJSON.base === 'object') {
            messageAddendum = '<strong>' + responseJSON.base[0] + '</strong>.'
          }
        }

        message.addClass('workflow-message-error').removeClass('workflow-message-saving')
        message.html('We had some problems saving. ' + messageAddendum)

        hideTimeout = setTimeout(hide, 4000)

        // Save errored, form still has unsaved changes
        GOVUKAdmin.Data.editionFormDirty = true

        if (Object.hasOwn(responseJSON, 'parts')) {
          partsError('errors.ajaxsave.admin', response)
        } else {
          element.trigger('errors.ajaxsave.admin', response)
        }
      }

      function showErrors (errors) {
        $.each(errors, function (errorKey, errorMessages) {
          var errorElement = element.find('#edition_' + errorKey)
          var parents = errorElement.parents('.form-group')
          parents.addClass('has-error')

          var list = parents.find('.error-block')
          for (var j = 0, m = errorMessages.length; j < m; j++) {
            list.append('<li>' + errorMessages[j] + '</li>')
          }
        })
      }

      function displayErrorSummaryComponent (errors) {
        createErrorSummaryComponent()

        $.each(errors, function (errorKey, errorMessages) {
          for (var i = 0, m = errorMessages.length; i < m; i++) {
            if (errorKey !== 'parts' && errorMessages[i] !== 'is invalid') {
              createAndAppendLinkToErrorSummaryComponent(errorKey, errorMessages[i])
            }
          }
        })
      }

      function createErrorSummaryComponent () {
        var heading = document.getElementsByClassName('page-title')[0]

        var div = document.createElement('div')
        div.id = 'error-summary'
        div.classList.add('alert', 'alert-danger')
        heading.after(div)

        var h3 = document.createElement('h3')
        h3.id = 'error-heading'
        h3.innerText = 'There is a problem'
        div.append(h3)

        var ul = document.createElement('ul')
        ul.classList.add('no-bullets')
        div.append(ul)
      }

      function createAndAppendLinkToErrorSummaryComponent (errorKey, errorMessage) {
        var ul = document.getElementsByClassName('no-bullets')[0]
        var list = document.createElement('li')
        var errorLink = document.createElement('a')
        errorLink.href = '#edition_' + errorKey
        errorLink.innerText = errorMessage
        ul.append(list)
        list.append(errorLink)
      }

      function destroyErrorSummaryComponent () {
        var errorSummaryComponent = document.getElementById('error-summary')

        if (errorSummaryComponent != null) {
          errorSummaryComponent.remove()
        }
      }

      function hideErrors () {
        element.find('.error-block').empty()
        element.find('.has-error').removeClass('has-error')
      }

      function saving () {
        reset()
        message.addClass('workflow-message-saving')
        message.text('Saving…')
      }

      function hide () {
        message.addClass('workflow-message-hide')
      }

      function reset () {
        hideErrors()
        destroyErrorSummaryComponent()
        clearTimeout(hideTimeout)
        message.removeClass(function (index, css) {
          return (css.match(/(^|\s)workflow-message-\S+/g) || []).join(' ')
        })
      }

      // parts functions
      function partsError (evt, response) {
        var responseJSON = response.responseJSON
        var partErrors = typeof responseJSON === 'object' && (responseJSON.parts || responseJSON.variants)
        if (partErrors) {
          $.each(partErrors[0], showPartErrors)
        }
      }

      function partsSuccess (evt, response) {
        var parts = response.parts || response.variants
        if (parts) {
          for (var i = 0, l = parts.length; i < l; i++) {
            updatePart(parts[i])
          }
        }
        removeDeletedParts()
      }

      function removeDeletedParts () {
        var deletedParts = $("[id*='__destroy'][value='1']")
        deletedParts.parents('.fields').remove()
      }

      function showPartErrors (partKey, partErrors) {
        var partKeyParts = partKey.split(':')
        var id = partKeyParts[0]
        var order = partKeyParts[1]
        var $partContainer = identifyPartContainer(id, order)

        $partContainer.find('.collapse').collapse('show')
        $.each(partErrors, function (fieldKey, messages) {
          var $errorElement = $partContainer.find('[id*=' + fieldKey + '_input]')

          $errorElement.addClass('has-error')
          var list = $errorElement.find('.error-block')
          for (var j = 0, m = messages.length; j < m; j++) {
            list.append('<li>' + messages[j] + '</li>')
            var elementId = '#' + $errorElement.find('input')[0].id
            appendPartErrorsToErrorSummaryComponent(elementId, messages[j])
          }
        })
      }

      function appendPartErrorsToErrorSummaryComponent (elementId, message) {
        var ul = document.getElementById('error-summary').childNodes[1]
        var list = document.createElement('li')
        var errorLink = document.createElement('a')
        errorLink.href = elementId
        errorLink.innerText = message
        ul.append(list)
        list.append(errorLink)
      }

      function updatePart (part) {
        var partId = part._id.$oid
        var $partContainer = identifyPartContainer(partId, part.order)
        var $hiddenInputId = $partContainer.find('input[value="' + partId + '"]')

        $partContainer.find('.js-part-title').text(part.title)
        $partContainer.find('.js-part-toggle-target').attr('id', part.slug)
        $partContainer.find('.js-part-toggle').attr('href', '#' + part.slug)

        if ($hiddenInputId.length === 0) {
          generateHiddenIdInput($partContainer, partId)
        }
      }

      function identifyPartContainer (id, order) {
        var $hiddenIdInput = element.find('input[value="' + id + '"]')
        var $order

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
        var $hiddenInputId = $('<input type="hidden">')
        var $titleInput = $partContainer.find('input.title')
        var namePrefix = $titleInput.attr('name').replace(/\[title\]/, '')
        var idPrefix = $titleInput.attr('id').replace(/_title/, '')

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
