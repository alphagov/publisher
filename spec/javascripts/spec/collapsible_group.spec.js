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
      <a href="#" class="js-toggle-all">Toggle all</a>\
      <div class="collapse"></div>\
      <div class="collapse"></div>\
      <div class="collapse"></div>\
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

  describe('when all items are closed', function() {
    it('expands all items' , function() {
      var toggle = element.find('.js-toggle-all');

      toggle.trigger('click');
      expect(element.find('.collapse.in').length).toBe(3);
    });
  });

  describe('when all items are open', function() {
    it('collapses all items' , function() {
      element.find('.collapse').addClass('in');

      var toggle = element.find('.js-toggle-all');

      expect(element.find('.collapse.in').length).toBe(3);
      toggle.trigger('click');
      expect(element.find('.collapse.in').length).toBe(0);
    });
  });

  describe('when at least one item is open', function() {
    it('collapses all items' , function() {
      element.find('.collapse').first().addClass('in');

      var toggle = element.find('.js-toggle-all');

      expect(element.find('.collapse.in').length).toBe(1);
      toggle.trigger('click');
      expect(element.find('.collapse.in').length).toBe(0);
    });
  });
});
