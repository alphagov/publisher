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
  var accordionSelector = ".js-sort-handle";
  var sortable_opts = {
    axis: "y",
    handle: accordionSelector,
    stop: function(event, ui) {
      $('.part').each(function (i, elem) {
        $(elem).find('input.order').val(i + 1);
        ui.item.find(accordionSelector).addClass("yellow-fade");
      });
    }
  }
  $('#parts').sortable(sortable_opts)
      .find(accordionSelector).css({cursor: 'move'});
  addAutoSlugGeneration();
});
