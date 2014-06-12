$(document).ready(function() {
  $.each(["business_size", "business_type", "purpose", "sector", "stage", "support_type"], function(idx, facet) {
    $("#business_support_" + facet + "_check_all").click(function(e) {
      var $el = $(e.target);
      $.each($el.parent().parent().find(":checkbox"), function(sidx, chkbx) {
        $(chkbx).attr("checked", ($el.attr("checked")?true:false));
      });
    });
  });
});
