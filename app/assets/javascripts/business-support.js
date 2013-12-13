$(document).ready(function() {
  $.each(["business_size", "business_type", "location", "purpose", "sector", "stage", "support_type"], function(idx, facet) {
    $("#business_support_" + facet + "_check_all").click(function(e) {
      var $el = $(e.target);
      $.each($el.parent().parent().find(":checkbox"), function(sidx, chkbx) {
        $(chkbx).attr("checked", ($el.attr("checked")?true:false));
      });
    });
  });

  /*
   * Checks all child regions when a country is checked.
   */
  var allLabels = $('#location').find('label');
  var countries = allLabels.filter(function () {
    return $(this).text().trim().match(/^England|Northern Ireland|Scotland|Wales$/);
  });

  countries.each (function (index, country) {
    $(country).children(":checkbox").on("click", function () {
      var countryLabel = $(country).text().trim();
      var countryMatch = (countryLabel == "England" ? /England|London|Yorkshire/ : countryLabel);

      var matches = allLabels.filter(function() {
        var matchText = $(this).text().trim();
        return matchText.match(countryMatch) && matchText != countryLabel;
      });

      var value = $(this).prop("checked");
      matches.each (function (index, match) {
        var checkbox = $(match).children(":checkbox");
        checkbox.attr("checked", value);
      });
    });
  });
});
