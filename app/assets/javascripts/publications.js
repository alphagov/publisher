// Javascript that may be used on every publication show/edit page

$(function () {
  /*
    Pre-submit a form, invoking a callback if the submission succeeds.

    This is mainly used for the action buttons other than "Save", where it
    makes sense to save the edition and perform the requested action if there
    aren't any errors.
  */
  var submit_form = function(form, success) {
    var jq = $.post(
      form.attr('action') + ".json",
      form.serialize(),
      success
    ).error( function(data) {
      var errors = $.parseJSON(data.responseText);
      var messages = "There were problems saving this edition: ";
      errors = $.map(errors, function(v,k) {
        return k + " " + v.join(", ");
      });
      messages = messages + errors.join("; ") + ".";
      $("<p class=\"flash-alert\">" + messages + "</p>").insertBefore("section.container-fluid:first");
    });
  }

  /* Apparently a lock variable to prevent multiple form submissions */
  var edition_form_saved = false;
  $('#save-edition').submit(function (e) {
    e.preventDefault();

    var edition_form = $('#edition-form');
    if (! edition_form_saved) {
      edition_form_saved = true;
      edition_form.trigger('submit');
    }
  });

  if (! 'autofocus' in document.createElement('input')) {
    $('*[autofocus]').focus();
  }

  /* Apparently a lock variable to prevent multiple form submissions */
  var edition_form_submitted = false;

  /*
    Mark the edition form as dirty to prevent accidental navigation away from
    the edition form (such as by clicking the "Edit in Panopticon" link)
  */
  var edition_form_dirty = false;

  $('#edition-form').change(function () {
    edition_form_dirty = true;
    edition_form_submitted = false;
  });

  $('#edition-form').submit(function() {
    edition_form_dirty = false;
  });

  $(window).bind('beforeunload', function() {
    if (edition_form_dirty) {
      return 'You have unsaved changes to this edition.';
    }
  });

  $('.also_save_edition').submit(function () {
    var edition_form = $('#edition-form');
    var this_form = $(this);

    if (edition_form_dirty && ! edition_form_submitted) {
      submit_form(edition_form, function () {
        edition_form_dirty = false;
        edition_form_submitted = true;
      });
    }
  });
});
