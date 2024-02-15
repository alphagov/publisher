/* global GOVUK */

describe('A downtime message module', function () {
  'use strict'

  let downtimeMessage, form

  const formHtml = `<form class="form well remove-top-margin" id="new_downtime" data-module="downtime-message"
      action="/editions/65ba0644e07788001e4e1c37/downtime" accept-charset="UTF-8" method="post"><input type="hidden"
                                                                                                       name="authenticity_token"
                                                                                                       value="lK-eQ7wGdDt5vMmzdL2WoPTIoSGtvld-eAQDlrao4zN4G6EIfwrGonmtOJSsiUxyNt9RN7hiBgpFaD9t-7WSZA"
                                                                                                       autocomplete="off">
    <input autocomplete="off" type="hidden" value="65ba0643e07788001e4e1c35" name="downtime[artefact_id]"
           id="downtime_artefact_id">
    <div class="govuk-grid-row">
        <div class="govuk-grid-column-full">
            <div class="govuk-grid-row">
                <div class="govuk-grid-column-one-half">
                    <div class="gem-c-fieldset govuk-form-group">
                        <fieldset class="govuk-fieldset">
                            <legend class="govuk-fieldset__legend govuk-fieldset__legend--m">From date</legend>
                            <div class="govuk-form-group">
                                <div id="hint-da6b7017" class="gem-c-hint govuk-hint govuk-!-margin-bottom-2">
                                    For example, 01 08 2022
                                </div>
                                <div class="gem-c-date-input govuk-date-input" id="input-7eba3d5d">
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-4e6660ad" class="gem-c-label govuk-label">Day</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-4e6660ad"
                                                   inputmode="numeric" name="from-date[day]" spellcheck="false"
                                                   type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-dd278c71" class="gem-c-label govuk-label">Month</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-dd278c71"
                                                   inputmode="numeric" name="from-date[month]" spellcheck="false"
                                                   type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-c655ec58" class="gem-c-label govuk-label">Year</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-4"
                                                   id="input-c655ec58"
                                                   inputmode="numeric" name="from-date[year]" spellcheck="false"
                                                   type="text">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
                <div class="govuk-grid-column-one-half">
                    <div class="gem-c-fieldset govuk-form-group">
                        <fieldset class="govuk-fieldset">
                            <legend class="govuk-fieldset__legend govuk-fieldset__legend--m">From time</legend>
                            <div class="govuk-form-group">
                                <div id="hint-5e9f4628" class="gem-c-hint govuk-hint govuk-!-margin-bottom-2">
                                    For example, 9:30 or 19:30
                                </div>
                                <div class="gem-c-date-input govuk-date-input" id="input-7d260dea">
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-7a3a41a1" class="gem-c-label govuk-label">Hour</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-7a3a41a1"
                                                   inputmode="numeric" name="from-time[hour]" spellcheck="false"
                                                   type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-662f9f21" class="gem-c-label govuk-label">Minute</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-662f9f21"
                                                   inputmode="numeric" name="from-time[minute]" spellcheck="false"
                                                   type="text">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="govuk-grid-row">
        <div class="govuk-grid-column-full">
            <div class="govuk-grid-row">
                <div class="govuk-grid-column-one-half">
                    <div class="gem-c-fieldset govuk-form-group">
                        <fieldset class="govuk-fieldset">
                            <legend class="govuk-fieldset__legend govuk-fieldset__legend--m">To date</legend>
                            <div class="govuk-form-group">
                                <div id="hint-cecadea2" class="gem-c-hint govuk-hint govuk-!-margin-bottom-2">
                                    For example, 01 08 2022
                                </div>
                                <div class="gem-c-date-input govuk-date-input" id="input-291f5da5">
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-16a32f90" class="gem-c-label govuk-label">Day</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-16a32f90" inputmode="numeric" name="to-date[day]"
                                                   spellcheck="false" type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-8d7d5a30" class="gem-c-label govuk-label">Month</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-8d7d5a30" inputmode="numeric" name="to-date[month]"
                                                   spellcheck="false" type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-3d609a01" class="gem-c-label govuk-label">Year</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-4"
                                                   id="input-3d609a01" inputmode="numeric" name="to-date[year]"
                                                   spellcheck="false" type="text">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
                <div class="govuk-grid-column-one-half">
                    <div class="gem-c-fieldset govuk-form-group">
                        <fieldset class="govuk-fieldset">
                            <legend class="govuk-fieldset__legend govuk-fieldset__legend--m">To time</legend>
                            <div class="govuk-form-group">
                                <div id="hint-b056facb" class="gem-c-hint govuk-hint govuk-!-margin-bottom-2">
                                    For example, 9:30 or 19:30
                                </div>
                                <div class="gem-c-date-input govuk-date-input" id="input-6449ba0b">
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-f956661e" class="gem-c-label govuk-label">Hour</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-f956661e" inputmode="numeric" name="to-time[hour]"
                                                   spellcheck="false" type="text">
                                        </div>
                                    </div>
                                    <div class="govuk-date-input__item">
                                        <div class="govuk-form-group">
                                            <label for="input-d1cdd592" class="gem-c-label govuk-label">Minute</label>
                                            <input class="gem-c-input govuk-input govuk-input--width-2"
                                                   id="input-d1cdd592" inputmode="numeric" name="to-time[minute]"
                                                   spellcheck="false" type="text">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="govuk-grid-row">
        <div class="govuk-grid-column-full">
            <div class="gem-c-textarea govuk-form-group govuk-!-margin-bottom-6">
                <label for="textarea-30759358" class="gem-c-label govuk-label govuk-label--l">Message</label>
                <div id="hint-2d54afbc" class="gem-c-hint govuk-hint">
                    Message is auto-generated once a schedule has been made.
                </div>
                <textarea name="message" class="govuk-textarea" id="textarea-30759358" rows="5" spellcheck="true"
                          aria-describedby="hint-2d54afbc">starting message</textarea>
            </div>
        </div>
    </div>
    <div class="govuk-button-group">
        <button class="gem-c-button govuk-button" type="submit" name="save" value="save">Save</button>
        <a class="govuk-link govuk-link--no-visited-state" href="/downtimes">Cancel</a>
    </div>
</form>`

  beforeEach(function () {
    form = document.createElement('form')
    form.innerHTML = formHtml
    document.body.appendChild(form)

    downtimeMessage = new GOVUK.Modules.DowntimeMessage(form)
    downtimeMessage.init(form)
  })

  afterEach(function () {
    form.remove()
  })

  describe('when initialising', function () {
    it('leaves any existing downtime message alone', function () {
      expectDowntimeMessageToMatch('starting message')
    })
  })

  describe('when entering dates', function () {
    it('generates a downtime message', function () {
      enterFromDate()
      enterToDate({ hour: '02' })
      expectDowntimeMessageToMatch('This service will be unavailable from 1am to 2am on Thursday 1 January.')

      enterToDate({ hour: '03' })
      expectDowntimeMessageToMatch('from 1am to 3am on Thursday 1 January.')
    })

    describe('that are the same', function () {
      beforeEach(function () {
        enterFromDate()
        enterToDate()
      })

      it('sets an empty message', function () {
        expectDowntimeMessageToBe('')
      })
    })

    describe('with a stop date before the start date', function () {
      beforeEach(function () {
        enterFromDate({ hour: '03' })
        enterToDate({ hour: '01' })
      })

      it('sets an empty message', function () {
        expectDowntimeMessageToBe('')
      })
    })

    describe('the generated messages', function () {
      it('use a 12 hour clock', function () {
        enterFromDate({ hour: '11' })
        enterToDate({ hour: '15' })
        expectDowntimeMessageToMatch('from 11am to 3pm on Thursday 1 January.')
      })

      it('use midnight instead of 12am', function () {
        enterFromDate({ hour: '00' })
        enterToDate({ hour: '02' })
        expectDowntimeMessageToMatch('from midnight to 2am on Thursday 1 January.')
      })

      it('use midday instead of 12pm', function () {
        enterFromDate({ hour: '12' })
        enterToDate({ hour: '14' })
        expectDowntimeMessageToMatch('from midday to 2pm on Thursday 1 January.')
      })

      it('includes minutes when they are not 0', function () {
        enterFromDate({ hour: '00', minutes: '15' })
        enterToDate({ hour: '02', minutes: '45' })
        expectDowntimeMessageToMatch('from 12:15am to 2:45am on Thursday 1 January.')
      })

      it('includes both dates when they differ', function () {
        enterFromDate()
        enterToDate({ day: '2', hour: '03' })
        expectDowntimeMessageToMatch('from 1am on Thursday 1 January to 3am on Friday 2 January.')
      })

      it('treats midnight on the next consecutive day as the same date', function () {
        enterFromDate({ hour: '22', day: '1' })
        enterToDate({ hour: '00', day: '2' })
        expectDowntimeMessageToMatch('from 10pm to midnight on Thursday 1 January.')
      })

      it('handles incorrect dates in the same way as rails', function () {
        enterFromDate({ day: '29', month: '2' })
        enterToDate({ day: '5', month: '3' })
        expectDowntimeMessageToMatch('from 1am on Sunday 1 March to 1am on Thursday 5 March.')
      })
    })
  })

  function expectDowntimeMessageToMatch (text) {
    expect(form.elements.message.value).toMatch(text)
  }

  function expectDowntimeMessageToBe (text) {
    expect(form.elements.message.value).toBe(text)
  }

  function enterFromDate (dateObj) {
    enterDate('from', dateObj)
  }

  function enterToDate (dateObj) {
    enterDate('to', dateObj)
  }

  function enterDate (selector, dateObj) {
    const day = form.elements[`${selector}-date[day]`]
    const month = form.elements[`${selector}-date[month]`]
    const year = form.elements[`${selector}-date[year]`]
    const hour = form.elements[`${selector}-time[hour]`]
    const minute = form.elements[`${selector}-time[minute]`]

    dateObj = dateObj || {}

    day.value = dateObj.day || '1'
    month.value = dateObj.month || '1'
    year.value = dateObj.year || '2015'
    hour.value = dateObj.hour || '1'
    minute.value = dateObj.minutes || '0'

    const event = new Event('change')
    form.dispatchEvent(event)
  }
})
