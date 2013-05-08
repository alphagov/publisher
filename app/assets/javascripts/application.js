//= require jquery
//= require jquery_ujs
//= require jquery-ui.custom.min
//= require jquery.mustache
//= require twitter/bootstrap
//= require_tree .

// System wide behaviours
$(function () {
  $('.flash-notice').delay(3000).slideUp(300).one('click', function () { $(this).slideUp(300); });

  $('a.preview').attr("target","_blank");
  $('form.preview').attr("target","_blank");

  $('.confirm form').submit(function(){
      return confirm('Woah. Scary action, cannot be undone. Continue?');
  });

  var $allPanels = $('#accordion div dl').hide();
  $allPanels.first().show();

  $('#accordion h3 a').click(function() {
    var $dl = $(this).parent().parent().find("dl");

    if ($dl.is(":visible")) {
      $dl.slideUp();
    } else {
      $dl.slideDown();
    }

    return false;
  });
})

// System wide library functions
var GovUKGuideUtils = {
  convertToSlug: function(title) {
    return title.toLowerCase().replace(/[^\w ]+/g,'').replace(/ +/g,'-');
  }
}
