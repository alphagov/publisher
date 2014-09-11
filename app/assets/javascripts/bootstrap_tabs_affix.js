// Switching tabs correctly toggles the 'active' class on
// .tab-pane elements only when .tab-pane elements are direct
// children of .tab-content. This fix is required for our
// scenario where .tab-pane is wrapped in the edition form.
$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
  $(e.target.hash).closest('.tab-content')
    .find('.tab-pane.active:not(' + e.target.hash + ')')
      .removeClass('active');
});
