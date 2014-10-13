describe('A collapsible group module', function() {
  "use strict";

  var group,
      element;

  beforeEach(function() {

    // Stub a bootstrap collapse method on jQuery
    $.fn.collapse = function(str) {
      if (str === "show") {
        $(this).addClass('in');
      } else if (str === "hide") {
        $(this).removeClass('in');
      }
    }

    element = $('<div>\
      <a href="#" class="js-expand-all">Expand</a>\
      <a href="#" class="js-collapse-all">Collapse</a>\
      <div class="collapse"></div>\
      <div class="collapse in"></div>\
    </div>');

    $('body').append(element);

    group = new GOVUKAdmin.Modules.CollapsibleGroup();
    group.start(element);
  });

  afterEach(function() {
    element.remove();

    // Delete bootstrap stub
    delete $.fn.collapse;
  });

  describe('clicking expand all', function() {
    it('expands all collapsible items' , function() {
      var expand = element.find('.js-expand-all');

      expand.trigger('click');
      expect(element.find('.collapse.in').length).toBe(2);
    });
  });

  describe('clicking collapse all', function() {
    it('collapses all collapsible items' , function() {
      var expand = element.find('.js-collapse-all');

      expand.trigger('click');
      expect(element.find('.collapse').length).toBe(2);
      expect(element.find('.collapse.in').length).toBe(0);
    });
  });
});
