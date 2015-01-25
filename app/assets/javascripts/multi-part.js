// Javascript specific to guide admin
$(document).on('nested:fieldAdded:parts', function(event){
  // Populate order field on newly created subform.
  $('.order', event.field).val($('#parts .fields').size());
});

function addAutoSlugGeneration() {

  $('#parts').on('change', 'input.title', function() {
    var elem = $(this);
    var value = elem.val();

    // Set slug on change.
    var slug_field = elem.closest('.part').find('.slug');
    if (slug_field.text() === '') {
      slug_field.val(GovUKGuideUtils.convertToSlug(value));
    }
  });
}

$(function() {
  addAutoSlugGeneration();
});
