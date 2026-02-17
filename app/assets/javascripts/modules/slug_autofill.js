window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function SlugAutofill ($module) {
    this.module = $module
    this.titleInputId = $module.dataset.titleInputId
    this.slugInputId = $module.dataset.slugInputId
  }

  SlugAutofill.prototype.init = function () {
    const titleInput = this.module.querySelector(`input[id="${this.titleInputId}"]`)
    const slugInput = this.module.querySelector(`input[id="${this.slugInputId}"]`)

    titleInput.addEventListener('change', populateSlug)

    function populateSlug () {
      if (slugInput.value === '' || slugInput.dataset.acceptsGeneratedValue === 'true') {
        slugInput.dataset.acceptsGeneratedValue = 'true'
        slugInput.value = convertToSlug(titleInput.value)
      }
    }

    function convertToSlug (title) {
      return title
        .trim()
        .toLowerCase()
        .replace(/[^\w -]+/g, '')
        .replace(/[ _]+/g, '-')
    }
  }

  Modules.SlugAutofill = SlugAutofill
})(window.GOVUK.Modules)
