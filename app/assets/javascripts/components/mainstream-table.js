(function (Modules) {
  function MainstreamTable ($module) {
    this.$module = $module
    // this.sectionClass = 'govuk-accordion__section'
    // this.sectionExpandedClass = 'govuk-accordion__section--expanded'
    // this.sectionInnerContentClass = 'govuk-accordion__section-content'
    // this.sectionButton = '.govuk-accordion__section-button'
    // this.sections = this.$module.querySelectorAll('.govuk-accordion__section')
    // this.openSections = 0
    // this.numSections = this.sections.length
    this.details = this.$module.querySelectorAll('.govuk-details')
    this.openDetails = 0
    this.numDetails = this.details.length
  }

  MainstreamTable.prototype.init = function () {
    console.log('init!')

    // Add Show/Hide All button to DOM
    // this.$module.querySelector('.govuk-table__header--controls').innerHTML = '<button type="button" class="govuk-accordion__show-all gem-c-accordion__show-all" aria-expanded="false"><span class="govuk-accordion-nav__chevron govuk-accordion-nav__chevron--down"></span><span class="govuk-accordion__show-all-text">Show all</span></button>'

    // Add Expand/Contract link to DOM
    var  expandLink = document.createElement('a')

    expandLink.classList.add('govuk-link', 'mainstream-table--expand-link')
    // expandLink.classList.add('govuk-link, mainstream-table--expand-link')
    expandLink.textContent = 'Expand all'

    this.$module.querySelector('.mainstream-table__heading').append(expandLink)

    // Add Event listener for Show All button
    // this.$module.querySelector('.govuk-accordion__show-all').addEventListener('click', this.toggleAllSections.bind(this))

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
