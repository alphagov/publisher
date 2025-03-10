window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function HistoryAndNotes ($module) {
    this.$module = $module
    this.toggleShowText = this.$module.dataset.toggleShowText
    this.toggleHideText = this.$module.dataset.toggleHideText
  }

  HistoryAndNotes.prototype.init = function () {
    this.setUp()
  }

  HistoryAndNotes.prototype.setUp = function () {
    const actions = this.$module.querySelectorAll('li')

    actions.forEach(element => {
      const commentEarlier = element.querySelector('.action--receive_fact_check--earlier') || null

      if (commentEarlier) {
        const toggle = document.createElement('a')

        toggle.className = 'govuk-link action--receive_fact_check--toggle govuk-!-font-weight-bold'
        toggle.textContent = this.toggleShowText
        toggle.href = '#'

        commentEarlier.classList.add('govuk-!-display-none')
        commentEarlier.parentNode.insertBefore(toggle, commentEarlier)

        toggle.addEventListener('click', (e) => {
          e.preventDefault()

          const hiddenClass = 'govuk-!-display-none'
          const toggle = e.target
          const earlierSection = toggle.parentNode.querySelector('.action--receive_fact_check--earlier')

          if (earlierSection.classList.contains('govuk-!-display-none')) {
            earlierSection.classList.remove(hiddenClass)
            toggle.text = this.toggleHideText
          } else {
            earlierSection.classList.add(hiddenClass)
            toggle.text = this.toggleShowText
          }
        })
      }
    })
  }

  Modules.HistoryAndNotes = HistoryAndNotes
})(window.GOVUK.Modules)
