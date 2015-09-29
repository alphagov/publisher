$(document).ready(function() {
  "use strict";

  var $relatedAreasSelect = $("#edition_areas"),
      bindAreasSelection = function (selector, filter) {
        $(selector).change(function () {
          var self = this;
          $('.areas-chkbx').each(function (i,e) {
            if (e !== self) $(e).prop('checked', false);
          });
          $relatedAreasSelect.select2("data", []);
          if ($(this).is(':checked')) {
            $relatedAreasSelect.select2("data", $.map(areas, filter));
          }
        });
      };

  // http://ivaynberg.github.io/select2/select-2.1.html
  $relatedAreasSelect.select2({
    width: "75%",
    placeholder: "Enter first few characters of the area name",
    minimumInputLength: 3,
    formatSelection : function (object) {
      return $("<span>")
               .addClass("js-area-name")
               .html(object.text)
               .wrap('<p>').parent().html();
    },
  });

  $relatedAreasSelect.on('select2-removed', function () {
    $('.areas-chkbx').prop('checked', false);
  });

  bindAreasSelection('#all_regions', function(area) {
    if (area.type === 'EUR') {
      return area;
    }
  });

  bindAreasSelection('#english_regions', function(area) {
    if (area.type === 'EUR' && area.country === 'England') {
      return area;
    }
  });
});
