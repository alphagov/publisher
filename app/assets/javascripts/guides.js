// Javascript specific to guide admin
$(function() {
  // collapse the parts using the bootstrap accordion
  $(".collapse").collapse();

  // simulate a click on the first part to open it
  $('#parts .part .accordion-body').first().collapse('show');

  $('input.title').
    live('change', function () {
      var title_field = $(this);
      var slug_field = title_field.closest('.part').find('.slug');
      if (slug_field.text() == '') {
        slug_field.val(GovUKGuideUtils.convertToSlug(title_field.val()));
      }
  });

  $('input.title').
    live('change', function () {
      var elem = $(this);
      var header = elem.closest('fieldset').prev('h3').find('a');
      header.text(elem.val());
    });

  $('.add-associated').bind('associated-added', function () {
    var active_index = $('#parts div.part').length;
    var new_part = $('#parts .part:last-child');
    new_part.find('.collapse').attr('id', 'new-part-' + active_index).collapse('show');
    new_part.find('a.accordion-toggle').attr('href', '#new-part-' + active_index);

    new_part.find('input.order').val(active_index);
    new_part.find('.title').focus();
  });
});