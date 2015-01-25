// Javascript specific to guide admin
// When we add a new part, ensure we add the auto slug generator handler
$(document).on('nested:fieldAdded:parts', function(event){
  addAutoSlugGeneration();

  // Populate order field on newly created subform.
  $('.order', event.field).val($('#parts .fields').size());
});

function addAutoSlugGeneration() {
  $('input.title').
    on('change', function () {
      var elem = $(this);
      var value = elem.val();

      // Set slug on change.
      var slug_field = elem.closest('.part').find('.slug');
      if (slug_field.text() === '') {
        slug_field.val(GovUKGuideUtils.convertToSlug(value));
      }

      // Set header on change.
      var header = elem.closest('fieldset').prev('h3').find('a');
      header.text(value);
    });
}

$(function() {
  addAutoSlugGeneration();
});
