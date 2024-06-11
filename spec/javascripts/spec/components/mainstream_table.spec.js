describe('Table component', function () {
  'use strict'

  var module, mainstreamTable

  beforeEach(function () {
    var moduleHtml =
      `<p class="mainstream-table__heading">50 documents</p>
      <table>
        <thead>
          <tr>
            <th class="govuk-table__header--expand">Title</th>
            <th>Updated</th>
            <th>Assigned to</th>
            <th>Status</th>
          </tr>
        </thead>
      </table>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    mainstreamTable = new GOVUK.Modules.MainstreamTable(module)
    mainstreamTable.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('When initialised', function () {
    it('should have a "Expand/Contract All" link', function () {
      var heading = module.querySelector('.mainstream-table__heading')

      expect(heading.querySelector('a')).not.toBeNull()
      expect(heading.querySelector('a').textContent).toBe('Expand all')
    })
  })
})
