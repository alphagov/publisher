$(document).ready(function() {
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

      var value = $(this).is(":checked");
      matches.each (function (index, match) {
        var checkbox = $(match).children(":checkbox");
        checkbox.prop("checked", value);
      });
    });
  });
});
