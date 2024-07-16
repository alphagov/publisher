describe('Table component', function () {
  'use strict'

  var module, publisherTable

  beforeEach(function () {
    var moduleHtml =
      `<p class="publisher-table__heading">20 documents</p>
      <table>
        <thead>
          <tr>
            <th>Title</th>
            <th>Updated</th>
            <th>Assigned to</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <p><a>Get an even faster decision on your visa or settlement application</a></p>
              <details class="govuk-details">
                <summary><span>More details</span></summary>
              </details>
            </td>
            <td><span>12 Dec 2023</span></td>
            <td>Keir Starmer</td>
            <td><span>Draft</span></td>
          </tr>
          <tr>
            <td>
              <p><a>Test Smart Answer</a></p>
              <details class="govuk-details">
                <summary><span>More details</span></summary>
              </details>
            </td>
            <td><span>11 Jul 2024</span></td>
            <td>Rishi Sunak</td>
            <td><span>Fact check</span></td>
          </tr>
          <tr>
            <td>
              <p><a>Gwneud cais i bleidleisio drwy’r post</a></p>
              <details class="govuk-details">
                <summary><span>More details</span></summary>
              </details>
            </td>
            <td><span>10 Jul 2024</span></td>
            <td>Liz Truss</td>
            <td><span>Amends needed</span></td>
          </tr>
        </tbody>
      </table>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    publisherTable = new GOVUK.Modules.PublisherTable(module)
    publisherTable.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('When initialised', function () {
    it('should have a "Expand/Collapse All" button', function () {
      var heading = module.querySelector('p.publisher-table__heading')

      expect(heading.querySelector('a')).not.toBeNull()
      expect(heading.querySelector('a').classList).toContain('publisher-table--expand-link')
      expect(heading.querySelector('a').textContent).toBe('Expand all')
    })
  })

  describe('The Expand/Contract all link', function () {
    var expandContractLink, detailsSections, event

    beforeEach(function () {
      expandContractLink = module.querySelector('p.publisher-table__heading a')
      detailsSections = module.querySelectorAll('details')
      event = new Event('click')
    })

    it('should be labelled "Expand all" when all of the "More details" sections are closed', function () {
      detailsSections[0].open = false
      detailsSections[1].open = false
      detailsSections[2].open = false
      publisherTable.openDetails = 0

      expect(expandContractLink.textContent).toBe('Expand all')
    })

    it('should be labelled "Expand all" when some of the "More details" sections are closed', function () {
      detailsSections[0].open = false
      detailsSections[1].open = true
      detailsSections[2].open = true
      publisherTable.openDetails = 2

      expect(expandContractLink.textContent).toBe('Expand all')
    })

    it('should open all the "More details" sections when all of them are closed', function () {
      detailsSections[0].open = false
      detailsSections[1].open = false
      detailsSections[2].open = false
      publisherTable.openDetails = 0

      expandContractLink.dispatchEvent(event)

      expect(publisherTable.openDetails).toBe(3)
      expect(detailsSections[0].open).toBe(true)
      expect(detailsSections[1].open).toBe(true)
      expect(detailsSections[2].open).toBe(true)
    })

    it('should open all the "More details" sections when some of them are closed', function () {
      detailsSections[0].open = false
      detailsSections[1].open = true
      detailsSections[2].open = true
      publisherTable.openDetails = 2

      expandContractLink.dispatchEvent(event)

      expect(publisherTable.openDetails).toBe(3)
      expect(detailsSections[0].open).toBe(true)
      expect(detailsSections[1].open).toBe(true)
      expect(detailsSections[2].open).toBe(true)
    })

    it('should be labelled "Collapse all" when all of the "More details" sections are open', function () {
      detailsSections[0].open = false
      detailsSections[1].open = false
      detailsSections[2].open = false
      publisherTable.openDetails = 0

      expandContractLink.dispatchEvent(event)

      expect(expandContractLink.textContent).toBe('Collapse all')
    })

    it('should close all the "More details" sections when they are all open', function () {
      detailsSections[0].open = true
      detailsSections[1].open = true
      detailsSections[2].open = true
      publisherTable.openDetails = 3

      expandContractLink.dispatchEvent(event)

      expect(publisherTable.openDetails).toBe(0)
      expect(detailsSections[0].open).toBe(false)
      expect(detailsSections[1].open).toBe(false)
      expect(detailsSections[2].open).toBe(false)
    })
  })
})
