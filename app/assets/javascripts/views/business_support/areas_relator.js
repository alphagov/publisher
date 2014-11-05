$(document).ready(function() {
  "use strict";

  var $relatedAreasWrapper = $(".related-areas"),
      $relatedAreasTextArea = $("#edition_areas"),
      prefillRelatedAreas = $relatedAreasTextArea.data("areas"),
      bindAreasSelection = function (selector, filter) {
        $(selector).change(function () {
          var self = this;
          $('.areas-chkbx').each(function (i,e) {
            if (e !== self) $(e).prop('checked', false);
          });
          $relatedAreasHiddenInput.select2("data", []);
          if ($(this).is(':checked')) {
            $relatedAreasHiddenInput.select2("data", $.map(areas, filter));
          }
        });
      },
      submitWithAreaArrayInputs = function (e) {
        e.preventDefault();
        var areaIds = $relatedAreasHiddenInput.attr("value").split(',');
        $relatedAreasHiddenInput.remove();
        for (var idx = 0; idx < areaIds.length; idx++) {
          $(this).append('<input name="edition[areas][]" type="hidden" value="'+areaIds[idx]+'"/>');
        }
        this.submit();
      };

  $relatedAreasWrapper
    .children("label")
    .html("Related areas");

  // select2 needs a hidden input to serve our purpose
  var $relatedAreasHiddenInput = $('<input type="hidden">')
                                      .attr("name", $relatedAreasTextArea.attr("name"))
                                      .attr("value", $relatedAreasTextArea.val());

  $relatedAreasTextArea.replaceWith($relatedAreasHiddenInput);
  $relatedAreasHiddenInput.addClass('form-control');

  $('#edition-form').submit(submitWithAreaArrayInputs);

  // http://ivaynberg.github.io/select2/select-2.1.html
  $relatedAreasHiddenInput.select2({
    width: "75%",
    multiple: true,
    placeholder: "Enter first few characters of the area name",
    minimumInputLength: 3,
    initSelection : function (element, callback) {
      callback(prefillRelatedAreas);
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

  $relatedAreasHiddenInput.on('select2-removed', function () {
    $('.areas-chkbx').prop('checked', false);
  });
  bindAreasSelection('#all_regions', function(area) {
    if (area.type === 'EUR') return area;
  });
  bindAreasSelection('#english_regions', function(area) {
    if (area.type === 'EUR' && area.country === 'England') return area;
  });
});
