/* global GOVUK */

describe('Table component', function () {
  'use strict'

  var table, mainstreamTable

  beforeEach(function () {
    table = $('<table data-module="mainstream-table"></table>')

    $('body').append(table)

    mainstreamTable = new GOVUK.Modules.MainstreamTable()
  })

  afterEach(function () {
    table.remove()
  })

  describe('when first initialized', function () {
    it('should do nothing', function() {
        expect(1).toBe(1)
    })
  })
})
