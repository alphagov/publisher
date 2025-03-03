window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function HistoryAndNotes ($module) {
    this.$module = $module
  }

  HistoryAndNotes.prototype.init = function () {
    this.setUp()
  }

  HistoryAndNotes.prototype.setUp = function () {
    const actions = this.$module.querySelectorAll('li')

    actions.forEach(element => {
      let commentEarlier = element.querySelector('.action--receive_fact_check--earlier') || null

      if (commentEarlier) {
        let toggle = document.createElement('a')

        toggle.className = "govuk-link action--receive_fact_check--toggle govuk-!-font-weight-bold"
        toggle.textContent = "Show earlier messages"
        toggle.href="#"

        commentEarlier.classList.add('govuk-!-display-none')
        commentEarlier.parentNode.insertBefore(toggle, commentEarlier)

        toggle.addEventListener('click', (e) => {
          e.preventDefault()

          const hiddenClass = 'govuk-!-display-none'
          let toggle = e.target
          let earlierSection = toggle.parentNode.querySelector('.action--receive_fact_check--earlier')

          if (earlierSection.classList.contains('govuk-!-display-none')) {
            earlierSection.classList.remove(hiddenClass)
            toggle.text = "Hide earlier messages"
          } else {
            earlierSection.classList.add(hiddenClass)
            toggle.text = "Show earlier messages"
          }
        })
      }
    })
  }

  Modules.HistoryAndNotes = HistoryAndNotes
})(window.GOVUK.Modules)
