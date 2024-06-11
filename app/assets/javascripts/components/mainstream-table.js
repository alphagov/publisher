(function (Modules) {
  function MainstreamTable ($module) {
    this.$module = $module
    this.details = this.$module.querySelectorAll('.govuk-details')
    this.openDetails = 0
    this.numDetails = this.details.length
  }

  MainstreamTable.prototype.init = function () {
    // Add Expand/Contract link to DOM
    this.addExpandlink()

    // Add Event listener for Expand All button
    // this.$module.querySelector('.govuk-table__header--expand').querySelector('a').addEventListener('click', this.toggleDetails.bind(this))

    // Add Event listener for Details sections
    this.$module.addEventListener('click', function(e) {
      if (e.target.classList.contains('govuk-details__summary')) {
        this.detailsStatus(e.target.parentNode)
      } else if (e.target.parentNode.classList.contains('govuk-details__summary')) {
        this.detailsStatus(e.target.parentNode.parentNode)
      }
    }.bind(this))

    // Add Event listeners for sections buttons
    // this.setUpSections()
  }

  // Add Expand/Contract link to DOM
  MainstreamTable.prototype.addExpandlink = function () {
    var  expandLink = document.createElement('a')
    expandLink.classList.add('govuk-link', 'mainstream-table--expand-link')
    expandLink.textContent = 'Expand all'
    this.$module.querySelector('.mainstream-table__heading').append(expandLink)
  }

  // Records status of Details sections
  MainstreamTable.prototype.detailsStatus = function (section) {
    var expandLink = this.$module.querySelector('.govuk-table__header--expand').querySelector('a')

    if (section.open == true) {
      this.openDetails--
    } else {
      this.openDetails++
    }

    if(this.openDetails == this.numDetails) {
      expandLink.textContent = 'Collapse all'
    } else {
      expandLink.textContent = 'Expand all'
    }
  }

  // Toggles the "More details" sections
  MainstreamTable.prototype.toggleDetails = function (e) {
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

  // Adds event listeners to set state of the "Show/Hide all" button when section buttons are clicked
  MainstreamTable.prototype.setUpSections = function () {
    this.sections.forEach(function (section) {
      section.querySelector('.govuk-accordion__section-heading').addEventListener('click', function () {
        if (section.classList.contains('govuk-accordion__section--expanded')) {
          this.openSections--

          if (this.openSections === this.numSections - 1) {
            this.toggleShowAllControls()
          }
        } else {
          this.openSections++

          if (this.openSections === this.numSections) {
            this.toggleShowAllControls()
          }
        }
      }.bind(this))
    }.bind(this))
  }

  // Toggles the "Show/Hide all" button
  MainstreamTable.prototype.toggleShowAllControls = function () {
    var showAllControls = this.$module.querySelector('.govuk-accordion__show-all')

    if (showAllControls.getAttribute('aria-expanded') === 'true') {
      showAllControls.querySelector('.govuk-accordion__show-all-text').textContent = 'Show all'
      showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--up')
      showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--down')
      showAllControls.setAttribute('aria-expanded', 'false')
    } else {
      showAllControls.querySelector('.govuk-accordion__show-all-text').textContent = 'Hide all'
      showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--down')
      showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--up')
      showAllControls.setAttribute('aria-expanded', 'true')
    }
  }

  MainstreamTable.prototype.toggleAllSections = function () {
    var controlAllState = this.$module.querySelector('.govuk-accordion__show-all').getAttribute('aria-expanded')
    var sections = this.$module.querySelectorAll('.' + this.sectionClass)

    // Open and close all sections
    sections.forEach(function (section) {
      var button = section.querySelector('button')

      if (section.classList.contains(this.sectionExpandedClass)) {
        if (controlAllState === 'true') {
          section.classList.remove(this.sectionExpandedClass)
          section.querySelector('.' + this.sectionInnerContentClass).hidden = 'until-found'
          button.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--down')
          button.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--up')
          button.querySelector('.govuk-accordion__section-toggle-text').textContent = 'Show'
          button.setAttribute('aria-expanded', 'false')
          this.openSections = 0
        }
      } else {
        if (controlAllState === 'false') {
          section.classList.add(this.sectionExpandedClass)
          section.querySelector('.' + this.sectionInnerContentClass).hidden = ''
          button.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--down')
          button.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--up')
          button.querySelector('.govuk-accordion__section-toggle-text').textContent = 'Hide'
          button.setAttribute('aria-expanded', 'true')
          this.openSections = this.numSections
        }
      }
    }.bind(this))

    this.toggleShowAllControls()
  }

  Modules.MainstreamTable = MainstreamTable
})(window.GOVUK.Modules)
