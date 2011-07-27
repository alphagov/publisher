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
      var publication_form = $('form.publication');
      if (! saved) {
          submit_form(publication_form,function() {
              saved = true;
              edition_form.trigger('submit');
          });
      }
      
      return saved;
  });
  
  $('input.title').
    live('change', function () {
      var title_field = $(this);
      var slug_field = title_field.closest('.part').find('.slug');
      if (slug_field.text() == '') {
        slug_field.val(GovUKGuideUtils.convertToSlug(title_field.val()));
      }
    });
    
  $('#edition_title')[0].focus();
  
  var submitted_forms = false;
  
  $('.also_save_edition').submit(function () {
    var edition_form = $('form.edition');
    var publication_form = $('form.publication');
    
    var this_form = $(this);

    if (! submitted_forms) {
        submit_form(edition_form,function(data) {
            console.log(data);
            submit_form(publication_form,function(data) {
                submitted_forms = true;
                this_form.trigger("submit");
            })
        });
    }
    return submitted_forms;
  });
});