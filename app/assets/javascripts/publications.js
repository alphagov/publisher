// Javascript that may be used on every publication show/edit page
$(function () {
  "use strict";

  /*
    Mark the edition form as dirty to prevent accidental navigation away from
    the edition form
  */
  GOVUKAdmin.Data = GOVUKAdmin.Data || {};
  GOVUKAdmin.Data.editionFormDirty = false;

  var $editionForm = $('#edition-form');

  $editionForm.change(function () {
    GOVUKAdmin.Data.editionFormDirty = true;
  });

  $editionForm.submit(function() {
    GOVUKAdmin.Data.editionFormDirty = false;
    /* prevent multiple form submissions */
    $("#save-edition").attr('disabled', true);
  });

  $(window).bind('beforeunload', function() {
    if (GOVUKAdmin.Data.editionFormDirty) {
      return 'You have unsaved changes to this edition.';
    }
  });

  $('.link-check-report').on('submit', '#link-checker-form', function () {
    if (GOVUKAdmin.Data.editionFormDirty) {
      alert('Please save your changes before running a link check.');
      return false;
    }
  });
});
