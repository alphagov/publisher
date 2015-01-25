// Javascript specific to guide admin
$(document).on('nested:fieldAdded:parts', function(event){
  // Populate order field on newly created subform.
  $('.order', event.field).val($('#parts .fields').size());
});
