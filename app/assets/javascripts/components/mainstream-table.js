(function (Modules) {
  function MainstreamTable ($module) {
    this.$module = $module
    this.sectionClass = 'govuk-accordion__section'
    this.sectionExpandedClass = 'govuk-accordion__section--expanded'
    this.sectionInnerContentClass = 'govuk-accordion__section-content'
    this.sectionButton = '.govuk-accordion__section-button'

    this.showAllControls = this.$module.querySelector('.govuk-accordion__show-all')
    this.sections = this.$module.querySelectorAll('.govuk-accordion__section')
    this.openSections = 0
    this.numSections = this.sections.length
  }

  MainstreamTable.prototype.init = function () {
    // Add Event listener for Show All button
    this.showAllControls.addEventListener('click', this.toggleAllSections.bind(this))

    // Add Event listeners for sections buttons
    this.setUpSections()
  }

  // Adds event listeners to set state of the "Show/Hide all" button when section buttons are clicked
  MainstreamTable.prototype.setUpSections = function () {
    this.sections.forEach(function(section) {
      section.querySelector('.govuk-accordion__section-heading').addEventListener('click', function() {
        if(section.classList.contains('govuk-accordion__section--expanded')) {
          this.openSections--

          if (this.openSections == this.numSections - 1) {
            this.toggleShowAllControls()
          }
        } else {
          this.openSections++

          if (this.openSections == this.numSections) {
            this.toggleShowAllControls()
          }
        }
      }.bind(this))
    }.bind(this))
  }

  // Toggles the "Show/Hide all" button
  MainstreamTable.prototype.toggleShowAllControls = function () {
    if (this.showAllControls.getAttribute('aria-expanded') == 'true') {
      this.showAllControls.querySelector('.govuk-accordion__show-all-text').textContent = 'Show all'
      this.showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--up')
      this.showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--down')
      this.showAllControls.setAttribute('aria-expanded', 'false')
    } else {
      this.showAllControls.querySelector('.govuk-accordion__show-all-text').textContent = 'Hide all'
      this.showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--down')
      this.showAllControls.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--up')
      this.showAllControls.setAttribute('aria-expanded', 'true')
    }
  }

  MainstreamTable.prototype.toggleAllSections = function () {
    var controlAllState = this.showAllControls.getAttribute('aria-expanded')
    var sections = this.$module.querySelectorAll('.' + this.sectionClass)

    // Open and close all sections
    sections.forEach(function(section) {
      var button = section.querySelector('button')

      if (section.classList.contains(this.sectionExpandedClass)) {
        if (controlAllState == 'true') {
          section.classList.remove(this.sectionExpandedClass)
          section.querySelector('.' + this.sectionInnerContentClass).hidden = "until-found"
          button.querySelector('.govuk-accordion-nav__chevron').classList.add('govuk-accordion-nav__chevron--down')
          button.querySelector('.govuk-accordion-nav__chevron').classList.remove('govuk-accordion-nav__chevron--up')
          button.querySelector('.govuk-accordion__section-toggle-text').textContent = 'Show'
          button.setAttribute('aria-expanded', 'false')
          this.openSections = 0
        }
      } else {
        if (controlAllState == 'false') {
          section.classList.add(this.sectionExpandedClass)
          section.querySelector('.' + this.sectionInnerContentClass).hidden = ""
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