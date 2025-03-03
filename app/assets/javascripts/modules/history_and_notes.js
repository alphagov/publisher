window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function HistoryAndNotes ($module) {
    this.$module = $module
  }

  HistoryAndNotes.prototype.init = function () {
    console.log("HistoryAndNotes init!")
    console.log("Module: ", this.$module)
  }

  Modules.HistoryAndNotes = HistoryAndNotes
})(window.GOVUK.Modules)
