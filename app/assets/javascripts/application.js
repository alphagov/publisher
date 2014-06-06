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

  var $allPanels = $('#edition-history div.accordion-body').hide();
  $allPanels.first().show();

  $('#edition-history a.accordion-toggle').click(function() {
    var $dl = $(this).parent().parent().find("div.accordion-body");
    $dl.slideToggle();
    return false;
  });
})

// System wide library functions
var GovUKGuideUtils = {
  convertToSlug: function(title) {
    return title.toLowerCase().replace(/[^\w ]+/g,'').replace(/ +/g,'-');
  }
}
