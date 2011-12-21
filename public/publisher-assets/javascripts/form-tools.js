var formtastic_ids = {};

$(function () {
  $('.add-associated').click(function () {
    elem = $(this);
    var target_id = elem.data('target');
    var target = $('#' + target_id);

    var template_id = elem.data('tmpl_id');
    template_contents = $('#' + template_id).html();

    if (typeof(formtastic_ids[template_id]) == 'undefined') {
      var current_id = target.find('fieldset input').last().attr('id').match(/_attributes_(\d+)_/)[1];
      formtastic_ids[template_id] = current_id;
    }

    formtastic_ids[template_id]++;

    var html = $.mustache(template_contents, {
      index: formtastic_ids[template_id]
    });

    target.append(html);
    $(this).trigger('associated-added');
    return false;
  });

  $('.remove-associated').live('click', function () {
    var css_selector = $(this).data('selector');
    $(this).parents(css_selector).hide();
    $(this).prev(':input').val('1');
    $('body').trigger('associated-removed');
    return false;
  })
});
