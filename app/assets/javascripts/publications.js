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

  /* Apparently a lock variable to prevent multiple form submissions */
  var submitted_forms = false;

  /*
    Mark the edition form as dirty to prevent accidental navigation away from
    the edition form (such as by clicking the "Edit in Panopticon" link)
  */
  var edition_form_dirty = false;

  $('form.edition').change(function () {
    submitted_forms = false;
    edition_form_dirty = true;
  });

  $('form.edition').submit(function() {
    edition_form_dirty = false;
    return true;
  });

  $(window).bind('beforeunload', function() {
    if (edition_form_dirty) {
      return 'You have unsaved changes to this edition.';
    }
  });

  $('.modal').modal('hide');

  $('.also_save_edition').submit(function () {
    var edition_form = $('form.edition');
    var this_form = $(this);

    if (! submitted_forms) {
      submit_form(edition_form, function () {
        submitted_forms = true;

        /*
          Need to clear the dirty flag manually, as the form hasn't officially
          been submitted
        */
        edition_form_dirty = false;
        this_form.trigger("submit");
      });
    }

    return submitted_forms;
  });
});

var GOVUK = GOVUK || {};
GOVUK.autoSave = (function() {
  var $form,
      autosaveInterval = 60000,
      autosaveHtml = '<span class="autosave-timestamp"></span>',
      formattedTime = function(date) {
        var zeroPad = function(num) {
          return num < 10 ? "0"+num : num;
        }
        return [zeroPad(date.getHours()), zeroPad(date.getMinutes()), zeroPad(date.getSeconds())].join(':');
      },
      updateTimestamp = function() {
        // TODO: While this timestamp is convenient for testing, it does not reflect the server update time accurately.
        // How important is this?
        $('.autosave-timestamp').text('Auto saved at ' + formattedTime(new Date()));
      }

  return {
    intervalId: null,
    dirty : false,

    init: function(form) {
      $form = form;

      $(window).bind('beforeunload', function() {
        if (GOVUK.autoSave.dirty) {
          return 'You have unsaved changes to this edition.';
        }
      });

      $form.submit(function() {
        GOVUK.autoSave.dirty = false;
        return true;
      });

      this.intervalId = setInterval(GOVUK.autoSave.run, autosaveInterval);
      // TODO: Does this accurately denote a change on the form?
      $form.on('keyup', function() { 
        GOVUK.autoSave.dirty = true;
      });

      if ($('.autosave-timestamp').length == 0) {
        $('.alert-info').append(autosaveHtml);
      }
    },
    completed : function(xhr, status) {
      GOVUK.autoSave.dirty = false;
      if (status == 'success') {
        updateTimestamp();
      }
    },
    run: function() {
      if (GOVUK.autoSave.dirty) {
        $.ajax({
          url : $form.attr('action').json,
          type : 'POST',
          data : $form.serialize(),
          complete : GOVUK.autoSave.completed
        });
      }
    }
  }
})();
GOVUK.autoSave.init($('form.edition'));
