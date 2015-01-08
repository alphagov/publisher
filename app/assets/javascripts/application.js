//= require select2
//= require moment
//= require jquery-ui.custom.min
//= require_directory .
//= require_directory ./modules
//= require jquery_nested_form

// System wide behaviours
$(function () {

  $('a.preview').attr("target","_blank");
  $('form.preview').attr("target","_blank");

  $('.confirm form').submit(function(){
      return confirm('Woah. Scary action, cannot be undone. Continue?');
  });

  $(".select2").select2();
})

// System wide library functions
var GovUKGuideUtils = {
  convertToSlug: function(title) {
    return title.toLowerCase().replace(/[^\w ]+/g,'').replace(/ +/g,'-');
  }
}
