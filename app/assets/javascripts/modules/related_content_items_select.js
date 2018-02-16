(function(Modules) {
  "use strict";
  Modules.RelatedContentItemsSelect = function() {
    this.start = function(element) {
      element.find("input[value='']").closest('li').remove();

      var $inputFields = element.find("input");
      $inputFields.prop('readonly', true);
      $inputFields.wrap('<div class="input-group"></div>');
      $inputFields.before('<span class="input-group-addon">&updownarrow;</span>');

      $('.js-list-sortable').sortable();
    }
  };
})(window.GOVUKAdmin.Modules);
