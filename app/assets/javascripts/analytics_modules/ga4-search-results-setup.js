'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  Modules.Ga4SearchResultsSetup = {
    init: function () {
      if (!document.querySelector('[data-ga4-ecommerce]')) {
        return
      }

      this.setSearchResultAttributes()
      this.trackEcommerce()
    },

    setSearchResultAttributes: function () {
      document.querySelectorAll('[data-ga4-ecommerce]').forEach((container) => {
        const startIndex = parseInt(container.dataset.ga4EcommerceStartIndex)
        const table = container.querySelector('table')

        if (!table) return

        table.querySelectorAll('tbody tr').forEach((row, rowIndex) => {
          // track links in the title column
          row
            .querySelectorAll('td a[data-ga4-ecommerce-content-id]')
            .forEach((link) => {
              link.setAttribute('data-ga4-ecommerce-path', link.href)
              link.setAttribute('data-ga4-ecommerce-index', rowIndex + 1)
            })

          // re-index any Details components to match the id of the search result
          const detailsComponent = row.querySelector('details')
          let ga4Event = JSON.parse(detailsComponent.dataset.ga4Event)

          ga4Event = {...ga4Event, ...{index_section: startIndex + parseInt(ga4Event.index_section) - 1}}
          detailsComponent.dataset.ga4Event = JSON.stringify(ga4Event)
        })
      })
    },

    trackEcommerce: function () {
      let searchTarget = document.querySelector('[data-ga4-ecommerce]')

      if (searchTarget) {
        searchTarget.setAttribute('data-ga4-ecommerce', true)

        if (!searchTarget.hasAttribute('data-ga4-ecommerce-started')) {
          window.GOVUK.analyticsGa4.Ga4EcommerceTracker.init()
        }

        searchTarget.setAttribute('data-ga4-ecommerce-started', true)
      }
    }
  }
})(window.GOVUK.analyticsGa4.analyticsModules)
