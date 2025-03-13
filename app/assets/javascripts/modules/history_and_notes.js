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
    let i = 1

    actions.forEach(element => {
      const commentEarlier = element.querySelector('.action--receive_fact_check--earlier') || null

      if (commentEarlier) {
        const toggle = document.createElement('button')

        commentEarlier.id = 'toggledContent_' + i
        toggle.className = 'history__action--receive_fact_check--toggle govuk-body govuk-link govuk-!-font-weight-bold'
        toggle.textContent = this.toggleShowText
        toggle.href = '#'
        toggle.setAttribute('aria-controls', commentEarlier.id)
        toggle.setAttribute('aria-expanded', false)

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
            toggle.setAttribute('aria-expanded', true)
          } else {
            earlierSection.classList.add(hiddenClass)
            toggle.text = this.toggleShowText
            toggle.setAttribute('aria-expanded', false)
          }
        })

        i++
      }
    })
  }

  Modules.HistoryAndNotes = HistoryAndNotes
})(window.GOVUK.Modules)
