window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  let form
  let titleInputId
  let slugInputId

  function SlugAutofill ($module) {
    form = $module
    titleInputId = $module.dataset.titleInputId
    slugInputId = $module.dataset.slugInputId
  }

  SlugAutofill.prototype.init = function () {
    const titleInput = form.querySelector(`input[id="${titleInputId || 'title'}"]`)
    const slugInput = form.querySelector(`input[id="${slugInputId || 'slug'}"]`)

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
