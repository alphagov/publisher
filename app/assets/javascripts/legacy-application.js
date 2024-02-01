//= require select2
//= require jquery-ui/widgets/sortable
//= require moment
//= require mousetrap
//= require jquery-ui.custom.min
//= require_directory ./vendor
//= require_directory .
//= require_directory ./legacy_modules
//= require jquery_nested_form

// System wide behaviours
$(function () {
  $('a.preview').attr('target', '_blank')
  $('form.preview').attr('target', '_blank')
  $('.select2').select2({ allowClear: true })
})

// System wide library functions
var GovUKGuideUtils = { // eslint-disable-line no-unused-vars
  convertToSlug: function (title) {
    return title.toLowerCase().replace(/[^\w ]+/g, '').replace(/ +/g, '-')
  }
}
