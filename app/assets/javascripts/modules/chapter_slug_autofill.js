window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  let form

  function ChapterSlugAutofill ($module) {
    form = $module
  }

  ChapterSlugAutofill.prototype.init = function () {
    const titleInput = form.querySelector('input[name="part[title]"]')
    const slugInput = form.querySelector('input[name="part[slug]"]')

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

  Modules.ChapterSlugAutofill = ChapterSlugAutofill
})(window.GOVUK.Modules)
