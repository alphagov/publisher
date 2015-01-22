describe('An ajax save with parts module', function() {
  "use strict";

  var ajaxSaveWithParts,
      element;

  beforeEach(function() {

    element = $('<form action="some/url">\
      <div class="js-status-message"></div>\
      <div class="fields">\
        <a href="#" class="js-part-toggle">\
          <span class="js-part-title">Title</span>\
        </a>\
        <div class="js-part-toggle-target" id="slug">\
          <div id="edition_parts_attributes_100_title_input">\
            <input class="title" type="text" id="edition_part_100_title" name="edition[part][100][title]" value="Title">\
          </div>\
          <input class="order" type="hidden" id="edition_part_100_order" name="edition[part][100][order]" value="1">\
          <div id="edition_parts_attributes_100_slug_input">\
            <input class="slug" type="text" id="edition_part_100_slug" name="edition[part][100][slug]" value="slug">\
          </div>\
          <input type="hidden" id="edition_part_100_id" name="edition[part][100][id]" value="5f00000001">\
        </div>\
      </div>\
      <div class="fields">\
        <a href="#" class="js-part-toggle">\
          <span class="js-part-title">Title 2</span>\
        </a>\
        <div class="js-part-toggle-target" id="slug-2">\
          <div id="edition_parts_attributes_101_title_input">\
            <input class="title" type="text" id="edition_part_101_title" name="edition[part][101][title]" value="Title 2">\
          </div>\
          <input class="order" type="hidden" id="edition_part_101_order" name="edition[part][101][order]" value="2">\
          <div id="edition_parts_attributes_101_slug_input">\
            <input class="slug" type="text" id="edition_part_101_slug" name="edition[part][101][slug]" value="slug-2">\
          </div>\
          <input type="hidden" id="edition_part_101_id" name="edition[part][101][id]" value="5f00000002">\
        </div>\
      </div>\
      <div class="fields">\
        <a href="#" class="js-part-toggle">\
          <span class="js-part-title">Untitled part</span>\
        </a>\
        <div class="js-part-toggle-target" id="untitled-part">\
          <div id="edition_parts_attributes_4535667_title_input">\
            <input class="title" type="text" id="edition_part_4535667_title" name="edition[part][4535667][title]" value="Updated title 3">\
          </div>\
          <input class="order" type="hidden" id="edition_part_4535667_order" name="edition[part][4535667][order]" value="3">\
          <div id="edition_parts_attributes_4535667_slug_input">\
            <input class="slug" type="text" id="edition_part_4535667_slug" name="edition[part][4535667][slug]" value="">\
          </div>\
        </div>\
      </div>\
      <input type="submit" class="js-save" value="Save">\
    </form>');

    $('body').append(element);
    ajaxSaveWithParts = new GOVUKAdmin.Modules.AjaxSaveWithParts();
    ajaxSaveWithParts.start(element);
  });

  afterEach(function() {
    element.remove();
  });

  describe('it does everything ajax save does', function() {
    describe('ie when clicking a save link', function() {
      it('posts the form using ajax', function() {
        spyOn($, 'ajax');
        element.find('.js-save').trigger('click');
        expect($.ajax).toHaveBeenCalled();
      });
    });
  });

  describe('when the form is saved successfully', function() {
    beforeEach(function() {
      element.trigger('success.ajaxsave.admin', {parts:
        [{_id: '5f00000001', order: 1, slug: 'updated-title-1', title: 'Updated title 1'},
         {_id: '5f00000002', order: 2, slug: 'updated-title-2', title: 'Updated title 2'}]
      });
    });

    it('updates the part titles based on their IDs', function() {
      expect(element.find('.js-part-title').eq(0).text()).toBe('Updated title 1');
      expect(element.find('.js-part-title').eq(1).text()).toBe('Updated title 2');
    });

    it('updates the toggle href and target based on its slug', function() {
      expect(element.find('.js-part-toggle-target').eq(0).attr('id')).toBe('updated-title-1');
      expect(element.find('.js-part-toggle-target').eq(1).attr('id')).toBe('updated-title-2')
      expect(element.find('.js-part-toggle').eq(0).attr('href')).toBe('#updated-title-1');
      expect(element.find('.js-part-toggle').eq(1).attr('href')).toBe('#updated-title-2');
    });
  });

  describe('when a new part is added and the form is saved', function() {
    beforeEach(function() {
      element.trigger('success.ajaxsave.admin', {parts:
        [{_id: '5f00000001', order: 1, slug: 'updated-title-1', title: 'Updated title 1'},
         {_id: '5f00000002', order: 2, slug: 'updated-title-2', title: 'Updated title 2'},
         {_id: '5f00000003', order: 3, slug: 'updated-title-3', title: 'Updated title 3'}]
      });
    });

    it('adds a hidden input containing the part’s new ID', function() {
      var $input = element.find('input[value="5f00000003"]');

      expect($input.length).toBe(1);
      expect($input.attr('id')).toBe('edition_part_4535667_id');
      expect($input.attr('name')).toBe('edition[part][4535667][id]');
    });

    it('updates the part’s title', function() {
      expect(element.find('.js-part-title').eq(2).text()).toBe('Updated title 3');
    });

    it('updates the toggle href and target based on its slug', function() {
      expect(element.find('.js-part-toggle-target').eq(2).attr('id')).toBe('updated-title-3');
      expect(element.find('.js-part-toggle').eq(2).attr('href')).toBe('#updated-title-3');
    });
  });

  describe('when the form save errors', function() {
    beforeEach(function() {
      element.trigger('error.ajaxsave.admin', {responseJSON: {"parts":
        [
          {
            "5f00000001:1":{"slug":["can't be blank","is invalid"]},
            "5f00000002:2":{"title":["can't be blank"]},
            "unknownid:3" :{"title":["must not walk on the grass"]}
          }
        ]
      }});
    });

    it('shows the error messages', function() {
      expect(element.find('.has-error').length).toBe(3);
      expect(element.find('ul.js-error').length).toBe(3);

      expect(element.find('#edition_parts_attributes_100_slug_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_parts_attributes_100_slug_input ul li').length).toBe(2);
      expect(element.find('#edition_parts_attributes_100_slug_input ul li:first').text()).toBe('can\'t be blank');
      expect(element.find('#edition_parts_attributes_100_slug_input ul li:last').text()).toBe('is invalid');

      expect(element.find('#edition_parts_attributes_101_title_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_parts_attributes_101_title_input ul li').length).toBe(1);
      expect(element.find('#edition_parts_attributes_101_title_input ul li:first').text()).toBe('can\'t be blank');

      expect(element.find('#edition_parts_attributes_4535667_title_input').is('.has-error')).toBe(true);
      expect(element.find('#edition_parts_attributes_4535667_title_input ul li').length).toBe(1);
      expect(element.find('#edition_parts_attributes_4535667_title_input ul li:first').text()).toBe('must not walk on the grass');
    });
  });
});
