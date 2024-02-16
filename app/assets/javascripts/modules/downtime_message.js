//= require govuk_publishing_components/vendor/polyfills/closest

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function DowntimeMessage ($module) {
    this.module = $module
  }

  DowntimeMessage.prototype.init = function () {
    const form = this.module

    form.addEventListener('change', updateMessage)

    function updateMessage () {
      const fromDate = getDate('start')
      const toDate = getDate('end')

      let message = ''
      if (isValidSchedule(fromDate, toDate)) {
        message = downtimeMessage(fromDate, toDate)
      }
      form.elements.message.value = message
    }

    function getDate (selector) {
      const day = form.elements[`downtime[${selector}_time(3i)]`].value
      const month = form.elements[`downtime[${selector}_time(2i)]`].value
      const year = form.elements[`downtime[${selector}_time(1i)]`].value
      const hours = form.elements[`downtime[${selector}_time(4i)]`].value
      const minutes = form.elements[`downtime[${selector}_time(5i)]`].value

      // The Date class treats 1 as February, but in the UI we expect 1 to be January
      const zeroIndexedMonth = parseInt(month) - 1
      return new Date(year, zeroIndexedMonth, day, hours, minutes)
    }

    function isValidSchedule (fromDate, toDate) {
      return toDate.getTime() > fromDate.getTime()
    }

    function downtimeMessage (fromDate, toDate) {
      let message = 'This service will be unavailable from'
      const fromDayText = getDayText(fromDate)
      const fromTime = getTime(fromDate)
      const toTime = getTime(toDate)
      const toDayText = getDayText(toDate)
      const sameDay = isSameDay(fromDate, toDate)

      if (!isValidSchedule(fromDate, toDate)) {
        return ''
      }

      if (sameDay) {
        message = `${message} ${fromTime} to ${toTime} on ${fromDayText}.`
      } else {
        message = `${message} ${fromTime} on ${fromDayText} to ${toTime} on ${toDayText}.`
      }

      return message
    }

    function getTime (date) {
      const time = date.toLocaleString(
        'en-GB',
        { hour: 'numeric', minute: 'numeric', hourCycle: 'h12' })
      return time.replace(/:00/, '')
        .replace(/ am/, 'am')
        .replace(/ pm/, 'pm')
        .replace(/12am/, 'midnight')
        .replace(/12pm/, 'midday')
    }

    function getDayText (date) {
      const dayText = date.toLocaleDateString(
        'en-GB',
        { weekday: 'long', month: 'long', day: 'numeric' }
      )
      return dayText.replace(/,/, '')
    }

    function isSameDay (fromDate, toDate) {
      // Treat a midnight stop date as being on the same day as
      // the hours before it. eg
      // Unavailable from 10pm to midnight on Thursday 8 January
      const toDateOneMinuteEarlier = new Date(toDate.valueOf())
      toDateOneMinuteEarlier.setMinutes(toDate.getMinutes() - 1)

      return fromDate.getFullYear() === toDateOneMinuteEarlier.getFullYear() &&
        fromDate.getMonth() === toDateOneMinuteEarlier.getMonth() &&
        fromDate.getDate() === toDateOneMinuteEarlier.getDate()
    }
  }

  Modules.DowntimeMessage = DowntimeMessage
})(window.GOVUK.Modules)
