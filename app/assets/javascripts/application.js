//= require select2
//= require jquery-ui/widgets/sortable
//= require selectize
//= require moment
//= require mousetrap
//= require jquery-ui.custom.min
//= require_directory ./vendor
//= require_directory .
//= require_directory ./modules
//= require jquery_nested_form

// System wide behaviours
$(function () {
  $('a.preview').attr("target","_blank");
  $('form.preview').attr("target","_blank");
  $(".select2").select2({ allowClear: true });
  $(".selectize").selectize({ plugins: ['drag_drop','remove_button'], closeAfterSelect: true, highlight: false });
})

// System wide library functions
var GovUKGuideUtils = {
  convertToSlug: function(title) {
    return title.toLowerCase().replace(/[^\w ]+/g,'').replace(/ +/g,'-');
  }
}
