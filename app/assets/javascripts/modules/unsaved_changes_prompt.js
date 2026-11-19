window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  let form
  let formSubmit = false
  let userChange = false

  function UnsavedChangesPrompt ($module) {
    form = $module
  }

  UnsavedChangesPrompt.prototype.init = function () {
    this.handleChanges()
    this.handleUnload()
  }

  UnsavedChangesPrompt.prototype.handleChanges = function () {
    form.addEventListener('submit', function () {
      formSubmit = true
    })

    form.addEventListener('change', function () {
      userChange = true
    })
  }

  UnsavedChangesPrompt.prototype.handleUnload = function () {
    window.addEventListener('beforeunload', function (e) {
      if (userChange && !formSubmit) {
        e.preventDefault()
      }
    })
  }

  Modules.UnsavedChangesPrompt = UnsavedChangesPrompt
})(window.GOVUK.Modules)
