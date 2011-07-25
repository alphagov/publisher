// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var GovUKGuideUtils = {
  convertToSlug: function(title) {
      return title
      .toLowerCase()
      .replace(/[^\w ]+/g,'')
      .replace(/ +/g,'-');
  }
}

$(function () {
  $('.flash-notice').delay(3000).slideUp(300).one('click', function () { $(this).slideUp(300); });
  
  $('a.preview').attr("target","_preview");
  $('form.preview').attr("target","_preview");
  
})