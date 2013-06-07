// Javascript specific to guide admin
$(function() {
  var sortable_opts = {
    axis: "y",
    handle: "a.accordion-toggle",
    stop: function(event, ui) {
      $('.part').each(function (i, elem) {
        $(elem).find('input.order').val(i + 1);
        ui.item.find("a.accordion-toggle").addClass("highlight");
        setTimeout(function() { $("a.accordion-toggle.highlight").removeClass("highlight") }, 20 )
      });
    }
  }
  $('#parts').sortable(sortable_opts)
      .find("a.accordion-toggle").css({cursor: 'move'});

  // simulate a click on the first part to open it
  $('#parts .part .accordion-body').first().collapse('show');

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
});
