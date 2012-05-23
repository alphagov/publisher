// Javascript specific to guide admin
$(function() {
  // collapse the parts using the bootstrap accordion
  $(".collapse").collapse();

  var sortable_opts = {
    axis: "y",
    handle: "a.accordion-toggle",
    stop: function() {
      $('.part').each(function (i, elem) {
        $(elem).find('input.order').val(i + 1);
      });
    }
  }
  $('#parts').sortable(sortable_opts);

  // simulate a click on the first part to open it
  $('#parts .part .accordion-body').first().collapse('show');

  $('input.title').
    live('change', function () {
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

  $('.add-associated').bind('associated-added', function () {
    var active_index = $('#parts div.part').length;
    var new_part = $('#parts .part:last-child');
    new_part.find('.collapse').attr('id', 'new-part-' + active_index).collapse('show');
    new_part.find('a.accordion-toggle').attr('href', '#new-part-' + active_index);

    new_part.find('input.order').val(active_index);
    new_part.find('.title').focus();
  });
});
