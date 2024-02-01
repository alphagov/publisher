//= require mermaid/dist/mermaid

(function (Modules) {
  'use strict'

  Modules.SmartAnswerFlowchart = function () {
    this.start = function (element) {
      var diagram = element.find('.flowchart')
      var flowchartLoading = element.find('.flowchart__loading')

      // eslint-disable-next-line
      mermaid.initialize(
        {
          startOnLoad: true,
          flowchart: {
            useMaxWidth: false
          }
        }
      )

      diagram.removeClass('flowchart--hidden')
      flowchartLoading.addClass('flowchart__loading--hidden')
    }
  }
})(window.GOVUKAdmin.Modules)
