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
        <tbody>
          <tr>
            <td>
              <p>The National Minimum Wage and Living Wage</p>
              <details class="govuk-details"></details>
            </td>
            <td>18 April 2024</td>
            <td>David Trussler</td>
            <td>Draft</td>
          </tr>
          <tr>
            <td>
              <p>Find software for filing company changes and registrations</p>
              <details class="govuk-details"></details>
            </td>
            <td>21 May 2024</td>
            <td>Jane Regan</td>
            <td>Awaiting 2i</td>
          </tr>
          <tr>
            <td>
              <p>Appeal an Illegal Migration Act decision</p>
              <details class="govuk-details"></details>
            </td>
            <td>22 May 2024</td>
            <td>Peter Wilkinson</td>
            <td>Amends needed</td>
          </tr>
        </tbody>
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

  describe('When the Expand/Contract All link is clicked', function () {
    it('should open or close all the details sections', function() {
      // TODO: check text of link is correct
      // TODO: check right number of links are open when some opened, some closed

      var click = new Event('click');
      var expandLink = module.querySelector('.mainstream-table__heading a')

      expandLink.dispatchEvent(click)
      expect(mainstreamTable.openDetails).toBe(3)

      expandLink.dispatchEvent(click)
      expect(mainstreamTable.openDetails).toBe(0)
    })
  })
})
