// Javascript that may be used on every publication show/edit page

$(function () {
  $('.publication-nav').tabs();

  var submit_form = function(form,success) {
     var jq = $.post(
         form.attr('action')+".json",
         form.serialize(),
         success
     ).error( function(data) {
         var errors = $.parseJSON(data.responseText);
         var messages = "There were problems saving this edition: ";
         errors = $.map(errors, function(v,k) {
             return k + " " + v.join(", ");
         });
         messages = messages + errors.join("; ") + ".";
         $("<p class=\"flash-alert\">"+messages+"</p>").insertBefore("#wrapper:first");
     });
   }

  var saved = false;

  $('#save-edition').submit(function () {
      var edition_form = $('form.edition');
      if (! saved) {
          saved = true;
          edition_form.trigger('submit');
      }

      return false;
  });

  if (! 'autofocus' in document.createElement('input')) {
    $('*[autofocus]').focus();
  }

  var submitted_forms = false;

  $('form.edition').change(function () {
    submitted_forms = false;
  });

  $('.also_save_edition').submit(function () {
    var edition_form = $('form.edition');
    var this_form = $(this);

    if (! submitted_forms) {
        submit_form(edition_form, function () {
            submitted_forms = true;
            this_form.trigger("submit");
        });
    }

    return submitted_forms;
  });
  
  $('.cancel_button').click(function () {
    $('.workflow_buttons').show();
    $(this).closest('form').hide();
    return false;
  })
  $(".review_button, .progress_button").submit(function () {
    var activity = this.id.replace('_toggle', '_form');
    $('#' + activity).toggle();
    $('.workflow_buttons').hide();
    return false;
  });
});

function close_popups() {
   var iframe = document.getElementById('popup');
   iframe.parentNode.removeChild(iframe);
}
