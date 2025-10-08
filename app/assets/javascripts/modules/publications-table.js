window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function PublicationsTable ($module) {
    this.$module = $module
    this.details = this.$module.querySelectorAll('.govuk-details')
    this.openDetailsCount = 0
    this.numDetails = this.details.length
  }

  PublicationsTable.prototype.init = function () {
    // Add Expand/Contract link to DOM
    this.addExpandlink()

    // Add Event listener for Expand All button
    this.$module.querySelector('.publications-table__heading a').addEventListener('click', this.toggleDetails.bind(this))
  }

  // Add Expand/Contract link to DOM
  PublicationsTable.prototype.addExpandlink = function () {
    var expandLink = document.createElement('a')
    expandLink.classList.add('govuk-link', 'publications-table--expand-link')
    expandLink.setAttribute('href', '#')
    expandLink.setAttribute('data-ga4-link', '{"action":"opened","event_name":"select_content","type":"Publications","text":"Collapse all"}')
    expandLink.textContent = 'Expand all'
    this.$module.querySelector('.publications-table__heading').append(expandLink)
  }

  // Toggles the "More details" sections
  PublicationsTable.prototype.toggleDetails = function (e) {
    if (this.openDetailsCount < this.numDetails) {
      this.details.forEach(function (section) {
        section.setAttribute('open', true)
      })

      this.openDetailsCount = this.numDetails
      e.target.setAttribute('data-ga4-link', '{"action":"opened","event_name":"select_content","type":"Publications","text":"Expand all"}')
      e.target.textContent = 'Collapse all'
    } else if (this.openDetailsCount === this.numDetails) {
      this.details.forEach(function (section) {
        section.removeAttribute('open')
      })

      this.openDetailsCount = 0
      e.target.setAttribute('data-ga4-link', '{"action":"closed","event_name":"select_content","type":"Publications","text":"Collapse all"}')
      e.target.textContent = 'Expand all'
    }
  }

  Modules.PublicationsTable = PublicationsTable
})(window.GOVUK.Modules)
