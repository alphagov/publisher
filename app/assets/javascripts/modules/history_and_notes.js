window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function HistoryAndNotes ($module) {
    this.$module = $module
  }

  HistoryAndNotes.prototype.init = function () {
    const actions = this.$module.querySelectorAll('li')

    actions.forEach(element => {
      let commentEarlier = element.querySelector('.action--receive_fact_check--earlier') || null

      if (commentEarlier) {
        commentEarlier.classList.add('govuk-!-display-none')
      }
    });
  }

  Modules.HistoryAndNotes = HistoryAndNotes
})(window.GOVUK.Modules)
