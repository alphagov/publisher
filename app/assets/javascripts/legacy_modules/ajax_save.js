/* globals Mousetrap */

(function (Modules) {
  'use strict'
  Modules.AjaxSave = function () {
    this.start = function (element) {
      const url = element.attr('action') + '.json'
      const message = element.find('.js-status-message')
      let requestRunning = false
      let hideTimeout

      GOVUKAdmin.Data = GOVUKAdmin.Data || {}
      element.on('click', '.js-save', save)
      Mousetrap.bindGlobal(['command+s', 'ctrl+s'], saveViaKeyboard)

      function saveViaKeyboard (evt) {
        if (element.find('.js-save:visible:enabled').length > 0) {
          save(evt)
        }
      }

      function save (evt) {
        const canPreventDefault = typeof evt.preventDefault === 'function'

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
          url,
          type: 'POST',
          data: element.serialize(),
          success,
          error,
          complete: function () {
            requestRunning = false
          }
        })
      }

      function allFieldsCanBeSavedWithAjax () {
        let ok = true
        element.find('.js-no-ajax, input[type="file"]').each(function () {
          const $input = $(this)
          const value = $input.val()

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
        const responseJSON = response.responseJSON
        let messageAddendum = 'Please check the form above.'

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

        element.trigger('errors.ajaxsave.admin', response)
      }

      function showErrors (errors) {
        $.each(errors, function (errorKey, errorMessages) {
          const errorElement = element.find('#edition_' + errorKey)
          const parents = errorElement.parents('.form-group')
          parents.addClass('has-error')

          const list = parents.find('.error-block')
          for (let j = 0, m = errorMessages.length; j < m; j++) {
            list.append('<li>' + errorMessages[j] + '</li>')
          }
        })
      }

      function displayErrorSummaryComponent (errors) {
        createErrorSummaryComponent()

        $.each(errors, function (errorKey, errorMessages) {
          for (let i = 0, m = errorMessages.length; i < m; i++) {
            if (errorKey !== 'parts' && errorMessages[i] !== 'is invalid') {
              createAndAppendLinkToErrorSummaryComponent(errorKey, errorMessages[i])
            }
          }
        })
      }

      function createErrorSummaryComponent () {
        const heading = document.getElementsByClassName('page-title')[0]

        const div = document.createElement('div')
        div.id = 'error-summary'
        div.classList.add('alert', 'alert-danger')
        heading.after(div)

        const h3 = document.createElement('h3')
        h3.id = 'error-heading'
        h3.innerText = 'There is a problem'
        div.append(h3)

        const ul = document.createElement('ul')
        ul.classList.add('no-bullets')
        div.append(ul)
      }

      function createAndAppendLinkToErrorSummaryComponent (errorKey, errorMessage) {
        const ul = document.getElementsByClassName('no-bullets')[0]
        const list = document.createElement('li')
        const errorLink = document.createElement('a')
        errorLink.href = '#edition_' + errorKey
        errorLink.innerText = errorMessage
        ul.append(list)
        list.append(errorLink)
      }

      function destroyErrorSummaryComponent () {
        const errorSummaryComponent = document.getElementById('error-summary')

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
    }
  }
})(window.GOVUKAdmin.Modules)
