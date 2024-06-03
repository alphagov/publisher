describe('Table component', function () {
  'use strict'

  var table, mainstreamTable

  beforeEach(function () {
    var tableHtml =
      `<thead>
        <tr>
          <th>Title</th>
          <th>Assigned to</th>
          <th>Status</th>
          <th class="govuk-table__header--controls"></th>
        </tr>
      </thead>`

    table = document.createElement('table')
    table.innerHTML = tableHtml
    document.body.appendChild(table)

    mainstreamTable = new GOVUK.Modules.MainstreamTable(table)
    mainstreamTable.init()
  })

  afterEach(function () {
    document.body.removeChild(table)
  })

  describe('When initialised', function () {
    it('should have a "Show/Hide All" button', function () {
      var headerControls = table.querySelector('th.govuk-table__header--controls')

      expect(headerControls.querySelector('button')).not.toBeNull()
      expect(headerControls.querySelector('button').classList).toContain('govuk-accordion__show-all')
      expect(headerControls.querySelector('button').textContent).toBe('Show all')
    })
  })
})
