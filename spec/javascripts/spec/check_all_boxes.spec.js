describe('A check all module', function() {
  "use strict";

  var checkAll,
      form;

  beforeEach(function() {

    form = $('<form>\
      <input type="checkbox" class="js-check-all">\
      <input type="checkbox">\
      <input type="checkbox" checked>\
      <input type="checkbox" checked="checked">\
      <input type="checkbox" disabled="disabled">\
    </form>');

    $('body').append(form);

    checkAll = new GOVUKAdmin.Modules.CheckAllBoxes();
    checkAll.start(form);
  });

  afterEach(function() {
    form.remove();
  });

  describe('clicking a check all checkbox', function() {
    it('toggles all enabled checkbox inputs to match' , function() {
      var checkbox = form.find('input.js-check-all');

      checkbox.trigger('click');
      expect(form.find(':checkbox:checked').length).toBe(4);
      expect(form.find(':checkbox:disabled:checked').length).toBe(0);

      checkbox.trigger('click');
      expect(form.find(':checkbox:checked').length).toBe(0);
    });
  });

  describe('clicking a disabled check all checkbox', function() {
    it('has no effect', function() {
      var checkbox = form.find('input.js-check-all');
      checkbox.prop('disabled', true);
      checkbox.trigger('click');

      expect(form.find(':checkbox:checked').length).toBe(2);
      expect(form.find(':checkbox:disabled').length).toBe(2);
      expect(form.find(':checkbox:disabled:checked').length).toBe(0);
    });
  });
});
