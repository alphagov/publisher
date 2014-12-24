$(document).ready(function() {
  "use strict";

  var $relatedAreasTextArea = $("#edition_areas"),
      bindAreasSelection = function (selector, filter) {
        $(selector).change(function () {
          var self = this;
          $('.areas-chkbx').each(function (i,e) {
            if (e !== self) $(e).prop('checked', false);
          });
          $relatedAreasTextArea.select2("data", []);
          if ($(this).is(':checked')) {
            $relatedAreasTextArea.select2("data", $.map(areas, filter));
          }
        });
      };

  // http://ivaynberg.github.io/select2/select-2.1.html
  $relatedAreasTextArea.select2({
    width: "75%",
    multiple: true,
    placeholder: "Enter first few characters of the area name",
    minimumInputLength: 3,
    initSelection : function (element, callback) {
      callback(element.data('areas'));
    },
    formatSelection : function (object) {
      return $("<span>")
               .addClass("js-area-name")
               .html(object.text)
               .wrap('<p>').parent().html();
    },
    data : { results : areas, text : 'name' },
    query : function (query) {
      var area,
          data = [],
          queryRe = new RegExp(query.term, "i"),
          len = areas.length;
      for (var idx = 0; idx < len; idx++) {
        area = areas[idx];
        if (queryRe.test(area.text)) {
          data.push(area);
        }
      }
      query.callback({ results: data });
    }
  });

  $relatedAreasTextArea.on('select2-removed', function () {
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
