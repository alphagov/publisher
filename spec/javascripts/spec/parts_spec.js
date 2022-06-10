describe('A parts module', function () {
  'use strict'

  var parts,
    element

  function createHtmlPasteEvent (html = null) {
    var event = new window.Event('paste')
    event.clipboardData = {
      getData: (type) => {
        if (type === 'text/html') {
          return html
        }
      }
    }

    return event
  }

  beforeEach(function () {
    element = $('<div>' +
      '<div id="part_1" class="part">' +
        '<div class="js-sort-handle">Part title 1</div>' +
        '<input class="title" name="part_1_title" type="text" value="Part title 1">' +
        '<input class="slug" name="part_1_slug" type="text" value="part-title-1">' +
        '<textarea class="body" name="part_1_body">part-body-1</textarea>' +
        '<input class="order" name="part_1_order" type="hidden" value="1">' +
      '</div>' +
      '<div id="part_2" class="part">' +
        '<div class="js-sort-handle">Part title 2</div>' +
        '<input class="title" name="part_2_title" type="text" value="Part title 2">' +
        '<input class="slug" name="part_2_slug" type="text" value="part-title-2">' +
        '<textarea class="body" name="part_2_body">part-body-2</textarea>' +
        '<input class="order" name="part_2_order" type="hidden" value="2">' +
      '</div>' +
      '<div id="part_3" class="part">' +
        '<div class="js-sort-handle">Part title 3</div>' +
        '<input class="title" name="part_3_title" type="text" value="Part title 3">' +
        '<input class="slug" name="part_3_slug" type="text" value="part-title-3">' +
        '<textarea class="body" name="part_3_body">part-body-3</textarea>' +
        '<input class="order" name="part_3_order" type="hidden" value="3">' +
      '</div>' +
    '</div>')

    $('body').append(element)
    parts = new GOVUKAdmin.Modules.Parts()
    parts.start(element)
  })

  afterEach(function () {
    element.remove()
  })

  describe('when sorting parts', function () {
    beforeEach(function (done) {
      $('#part_1').simulateDragSortable({ move: 2, handle: '.js-sort-handle' })

      // Wait briefly until jquery ui has done its thing
      setTimeout(function () {
        done()
      }, 50)
    })

    it('saves their order in the hidden order input', function () {
      expect($('#part_2').find('.order').val()).toBe('1')
      expect($('#part_3').find('.order').val()).toBe('2')
      expect($('#part_1').find('.order').val()).toBe('3')
    })

    it('adds a yellow fade class to the element moved', function () {
      expect(element.find('.js-sort-handle.yellow-fade').length).toBe(1)
      expect($('#part_1').find('.js-sort-handle.yellow-fade').length).toBe(1)
    })
  })

  describe('when adding a part', function () {
    beforeEach(function () {
      element.append('<div id="part_4" class="part">' +
        '<div class="js-sort-handle"></div>' +
        '<input class="error has-error title" name="part_4_title" type="text" value="">' +
        '<input class="slug" name="part_4_slug" type="text" value="">' +
        '<textarea class="body" name="part_4_body"></textarea>' +
        '<input class="order" name="part_4_order" type="hidden" value="">' +
        '<div class="error has-error" id="error-block">Error</div>' +
      '</div>')
      element.trigger('nested:fieldAdded:parts')
    })

    it('updates the part orders', function () {
      expect($('#part_4').find('.order').val()).toBe('4')
    })

    it('allows the part to be sortable', function (done) {
      $('#part_4').simulateDragSortable({ move: -2, handle: '.js-sort-handle', tolerance: 0 })

      // Wait briefly until jquery ui has done its thing
      setTimeout(function () {
        expect($('#part_1').find('.order').val()).toBe('1')
        expect($('#part_4').find('.order').val()).toBe('2')
        expect($('#part_2').find('.order').val()).toBe('3')
        expect($('#part_3').find('.order').val()).toBe('4')
        done()
      }, 50)
    })

    it('removes validation errors on the newly added part', function () {
      expect($('#part_4').find('.error, .has-error').length).toBe(0)
    })

    it('applies the paste html to govspeak data module to the new parts body field', function () {
      var $textarea = $('#part_4').find('.body')[0]
      $textarea.dispatchEvent(createHtmlPasteEvent('<h2>This is a h2</h2>'))

      expect($textarea.value).toEqual('## This is a h2')
    })
  })

  describe('when editing a part’s title', function () {
    it('updates that part’s slug if it was empty', function () {
      $('#part_1').find('.slug').val('')
      $('#part_1').find('.title').val('New title').trigger('change')

      expect($('#part_1').find('.slug').val()).toBe('new-title')
      expect($('#part_2').find('.slug').val()).toBe('part-title-2')
      expect($('#part_3').find('.slug').val()).toBe('part-title-3')
    })

    it('updates that part’s slug if the slug accepts generated values', function () {
      $('#part_1').find('.slug').data('accepts-generated-value', true)
      $('#part_1').find('.title').val('New title').trigger('change')

      expect($('#part_1').find('.slug').val()).toBe('new-title')
    })

    it('continues to update a slug if it begun empty', function () {
      $('#part_1').find('.slug').val('')
      $('#part_1').find('.title').val('New title').trigger('change')
      $('#part_1').find('.title').val('Another change').trigger('change')

      expect($('#part_1').find('.slug').val()).toBe('another-change')
    })

    it('leaves alone slugs that didn’t begin as empty', function () {
      $('#part_1').find('.title').val('New title').trigger('change')
      expect($('#part_1').find('.slug').val()).toBe('part-title-1')
    })
  })
})
