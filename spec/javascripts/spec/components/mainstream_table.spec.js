describe('Table component', function () {
  'use strict'

  var table, mainstreamTable

  beforeEach(function () {
    var tableHtml =
      `<thead>
        <tr>
          <th class="govuk-table__header--expand">Title</th>
          <th>Updated</th>
          <th>Assigned to</th>
          <th>Status</th>
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
    it('should have a "Expand/Contract All" link', function () {
      var expander = table.querySelector('th.govuk-table__header--expand')

      expect(expander.querySelector('a')).not.toBeNull()
      expect(expander.querySelector('a').textContent).toBe('Expand all')
    })
  })
})
