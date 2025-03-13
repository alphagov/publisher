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
    module.setAttribute('data-toggle-show-text', 'Show earlier messages')
    module.setAttribute('data-toggle-hide-text', 'Hide earlier messages')
    document.body.appendChild(module)

    historyAndNotes = new window.GOVUK.Modules.HistoryAndNotes(module)
    historyAndNotes.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('"Receive fact check" actions', function () {
    it('should hide "action--receive_fact_check--earlier" sections where they exist', function () {
      const actions = module.querySelectorAll('li')

      expect(actions[0].querySelector('.action--receive_fact_check--earlier')).toBe(null)
      expect(actions[1].querySelector('.action--receive_fact_check--earlier')).toBe(null)
      expect(actions[2].querySelector('.action--receive_fact_check--earlier').classList.contains('govuk-!-display-none')).toBe(true)
      expect(actions[3].querySelector('.action--receive_fact_check--earlier').classList.contains('govuk-!-display-none')).toBe(true)
    })

    it('should display "Show earlier messages" buttons where there is a hidden section', function () {
      const actions = module.querySelectorAll('li')

      expect(actions[0].querySelector('button')).toBe(null)
      expect(actions[1].querySelector('button')).toBe(null)
      expect(actions[2].querySelector('button').textContent).toEqual('Show earlier messages')
      expect(actions[2].querySelector('button').getAttribute('aria-controls')).toEqual('toggledContent_1')
      expect(actions[2].querySelector('button').getAttribute('aria-expanded')).toEqual('false')
      expect(actions[3].querySelector('button').textContent).toEqual('Show earlier messages')
      expect(actions[3].querySelector('button').getAttribute('aria-controls')).toEqual('toggledContent_2')
      expect(actions[3].querySelector('button').getAttribute('aria-expanded')).toEqual('false')
    })

    it('should add IDs to the hidden sections', function () {
      const actions = module.querySelectorAll('li')

      expect(actions[2].querySelector('.action--receive_fact_check--earlier').id).toEqual('toggledContent_1')
      expect(actions[3].querySelector('.action--receive_fact_check--earlier').id).toEqual('toggledContent_2')
    })

    it('should toggle the display of the hidden section when the "Show earlier messages" link is clicked', function () {
      const action = module.querySelectorAll('li')[2]
      const toggle = action.querySelector('button')
      const click = new Event('click')

      toggle.dispatchEvent(click)

      expect(action.querySelector('.action--receive_fact_check--earlier').classList.contains('govuk-!-display-none')).toBe(false)
      expect(toggle.text).toEqual('Hide earlier messages')
      expect(toggle.getAttribute('aria-expanded')).toEqual('true')

      toggle.dispatchEvent(click)

      expect(action.querySelector('.action--receive_fact_check--earlier').classList.contains('govuk-!-display-none')).toBe(true)
      expect(toggle.text).toEqual('Show earlier messages')
      expect(toggle.getAttribute('aria-expanded')).toEqual('false')
    })
  })
})
