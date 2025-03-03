window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}

describe('History and Notes component', function () {
  'use strict'

  var module, historyAndNotes

  beforeEach(function () {
    var moduleHtml =
      `<ul>
        <li>
          <div>
            <div class="action--note__content">
              <p>A current message</p>
            </div>
          </div>
        </li>
        <li>
          <div>
            <div class="action--receive_fact_check__content">
              <p>A current message</p>
            </div>
          </div>
        </li>
        <li>
          <div>
            <div class="action--receive_fact_check__content">
              <p>A current message</p>
              <div class="action--receive_fact_check--earlier">
                <p>An earlier message</p>
                <p>Another earlier message</p>
              </div>
            </div>
          </div>
        </li>
      </ul>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    historyAndNotes = new window.GOVUK.Modules.HistoryAndNotes(module)
    historyAndNotes.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('"Receive fact check" actions', function () {
    it('should hide "history__action--receive_fact_check--earlier" sections where they exist', function () {
      const actions = module.querySelectorAll("li")

      expect(actions[0].querySelector('.action--receive_fact_check--earlier')).toBe(null)
      expect(actions[1].querySelector('.action--receive_fact_check--earlier')).toBe(null)
      expect(actions[2].querySelector('.action--receive_fact_check--earlier').classList.contains("govuk-!-display-none")).toBe(true)
    })

    xit('should display a "Show earlier messages" link where there is a hidden section', function () {
      expect(1).toEqual(1)
    })

    xit('should toggle the display of the hidden section when the "Show earlier messages" link is clicked', function () {
      expect(1).toEqual(1)
    })
  })
})
