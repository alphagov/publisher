// Javascript that may be used on every publication show/edit page

$(function () {
  if (! 'autofocus' in document.createElement('input')) {
    $('*[autofocus]').focus();
  }

  /*
    Mark the edition form as dirty to prevent accidental navigation away from
    the edition form (such as by clicking the "Edit in Panopticon" link)
  */
  var edition_form_dirty = false;

  $('#edition-form').change(function () {
    edition_form_dirty = true;
  });

  $('#edition-form').submit(function() {
    edition_form_dirty = false;
    /* prevent multiple form submissions */
    $("#save-edition").attr('disabled', true);
  });

  $(window).bind('beforeunload', function() {
    if (edition_form_dirty) {
      return 'You have unsaved changes to this edition.';
    }
  });
});
