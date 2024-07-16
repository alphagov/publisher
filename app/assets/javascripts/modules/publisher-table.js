(function (Modules) {
  function PublisherTable ($module) {
    this.$module = $module
    this.details = this.$module.querySelectorAll('.govuk-details')
    this.openDetails = 0
    this.numDetails = this.details.length
  }

  PublisherTable.prototype.init = function () {
    // Add Expand/Contract link to DOM
    this.addExpandlink()

    // Add Event listener for Expand All button
    this.$module.querySelector('.publisher-table__heading a').addEventListener('click', this.toggleDetails.bind(this))
  }

  // Add Expand/Contract link to DOM
  PublisherTable.prototype.addExpandlink = function () {
    var  expandLink = document.createElement('a')
    expandLink.classList.add('govuk-link', 'publisher-table--expand-link')
    expandLink.textContent = 'Expand all'
    this.$module.querySelector('.publisher-table__heading').append(expandLink)
  }

  // Toggles the "More details" sections
  PublisherTable.prototype.toggleDetails = function (e) {
    if (this.openDetails < this.numDetails) {
      this.details.forEach(function(section) {
        section.setAttribute('open', true)
      })

      this.openDetails = this.numDetails
      e.target.textContent = 'Collapse all'
    } else if (this.openDetails == this.numDetails) {
      this.details.forEach(function(section) {
        section.removeAttribute('open')
      })

      this.openDetails = 0
      e.target.textContent = 'Expand all'
    }
  }

  Modules.PublisherTable = PublisherTable
})(window.GOVUK.Modules)
