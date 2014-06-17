//= require jquery-ui.custom.min
//= require_directory .
//= require jquery_nested_form

// System wide behaviours
$(function () {
  $('.flash-notice').delay(3000).slideUp(300).one('click', function () { $(this).slideUp(300); });

  $('a.preview').attr("target","_blank");
  $('form.preview').attr("target","_blank");

  $('.confirm form').submit(function(){
      return confirm('Woah. Scary action, cannot be undone. Continue?');
  });
})

// System wide library functions
var GovUKGuideUtils = {
  convertToSlug: function(title) {
    return title.toLowerCase().replace(/[^\w ]+/g,'').replace(/ +/g,'-');
  }
}
