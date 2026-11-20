(function () {
  'use strict'

  const root = this
  const $ = root.jQuery
  if (typeof root.Publisher === 'undefined') { root.Publisher = {} }

  const smartAnswerBuilder = {
    init: function () {
      smartAnswerBuilder.setEventHandlers()
      smartAnswerBuilder.reloadAllNextNodeLists()
      smartAnswerBuilder.setupInitialQuestion()
    },
    lastNodeKind: null,
    setEventHandlers: function () {
      smartAnswerBuilder.addQuestionButton().click(smartAnswerBuilder.addQuestion)
      smartAnswerBuilder.addOutcomeButton().click(smartAnswerBuilder.addOutcome)

      $('.nodes').on('change', '.node input.node-title', smartAnswerBuilder.reloadAllNextNodeLists)
      $('.nodes').on('change', '.node select.next-node-list', smartAnswerBuilder.updateNextNode)

      $(document).on('nested:fieldAdded:nodes', smartAnswerBuilder.initNode)
      $(document).on('nested:fieldRemoved:nodes', smartAnswerBuilder.reloadAllNextNodeLists)

      $(document).on('nested:fieldAdded:options', smartAnswerBuilder.initOption)
    },
    container: $('.builder-container'),
    addQuestion: function () {
      smartAnswerBuilder.lastNodeKind = 'question'
    },
    addOutcome: function () {
      smartAnswerBuilder.lastNodeKind = 'outcome'
    },
    addQuestionButton: function () {
      return smartAnswerBuilder.container.find('a.add-question')
    },
    addOutcomeButton: function () {
      return smartAnswerBuilder.container.find('a.add-outcome')
    },
    setupInitialQuestion: function () {
      if (smartAnswerBuilder.container.find('.node').length < 1) {
        smartAnswerBuilder.addQuestionButton().click()
      }
    },
    initNode: function (e) {
      const kind = smartAnswerBuilder.lastNodeKind
      const index = smartAnswerBuilder.indexOfKind(kind)

      const node = e.field
      smartAnswerBuilder.lastNodeKind = null

      node.find('input.node-kind').val(kind)
      node.find('input.node-slug').val(nodeId(kind, index))

      node.find('.node-label').text(nodeLabel(kind, index))
      node.addClass(kind).attr('id', nodeId(kind, index))
      node.find('.remove-node-label').text('Remove ' + kind)

      const body = node.find('.node-body')
      addPasteHtmlToGovspeak(body)

      const questions = $('.nodes .question:visible')
      const outcomes = $('.nodes .outcome:visible')

      if (kind === 'outcome') {
        node.find('.options').remove()

        let i = 0
        if (outcomes.length > 1) {
          i = outcomes.eq(-2).find('input.node-order').val()
        } else {
          if (questions.length > 0) {
            i = questions.last().find('input.node-order').val()
          }
        };
        node.find('input.node-order').val(parseInt(i) + 1)
      } else {
        node.find('.options .add_nested_fields').click()
        node.find('input.node-title').attr('placeholder', 'The title of the question')

        questions.each(function (i) {
          $(this).find('input.node-order').val(i + 1)
        })

        if (questions.length > 1) {
          node.insertAfter(questions[questions.length - 2])
        } else {
          $('.nodes').prepend(node)
        };

        outcomes.each(function (i) {
          $(this).find('input.node-order').val(questions.length + i + 1)
        })
      }

      smartAnswerBuilder.reloadAllNextNodeLists()

      function nodeId (kind, index) {
        return kind + '-' + index
      }

      function nodeLabel (kind, index) {
        const capitalizedKind = kind.charAt(0).toUpperCase() + kind.slice(1)
        return capitalizedKind + ' ' + index
      }

      function addPasteHtmlToGovspeak (field) {
        const pasteHtmlToGovspeak = new GOVUKAdmin.Modules.PasteHtmlToGovspeak()
        pasteHtmlToGovspeak.start(field)
      }
    },
    indexOfKind: function (kind) {
      const kindMatch = new RegExp(kind + '-')
      const indexes = smartAnswerBuilder.container.find('.node.' + kind + ' .node-slug').map(function () {
        const index = $(this).val().replace(kindMatch, '')
        return parseInt(index)
      }).get()
      if (indexes.length < 1) {
        return 1
      } else {
        const max = Math.max.apply(null, indexes)
        return max + 1
      }
    },
    initOption: function (e) {
      const option = $(e.field)
      const node = option.parents('.node').first()
      let maxOrder = 0

      // Find the maximum order value in the list of existing options
      node.find('.option:visible .option-order')
        .not(option.find('.option-order')).each(function () {
          const val = parseInt($(this).val())
          if (val > maxOrder) { maxOrder = val }
        })

      // Set the hidden input order value for the new option to maxOrder + 1
      option.find('.option-order').val(maxOrder + 1)

      smartAnswerBuilder.reloadNextNodeList(node)
    },
    reloadAllNextNodeLists: function () {
      $.each(smartAnswerBuilder.container.find('.node'), function (i, node) {
        smartAnswerBuilder.reloadNextNodeList($(node))
      })
    },
    reloadNextNodeList: function (node) {
      const nextNodeField = node.find('.next-node-list')
      nextNodeField.find('option:not(.default)').remove()

      const validNextNodes = smartAnswerBuilder.optionsForNode(node)
      const validNextIds = $.map(validNextNodes, function (n) { return n.id })

      $.each(validNextNodes, function (i, x) {
        let optionLabel = x.name
        if (x.label !== '') {
          optionLabel = optionLabel + ' (' + x.label + ')'
        }
        $('<option></option>').text(optionLabel).attr('value', x.id).appendTo(nextNodeField.find('optgroup[class="' + x.kind + '-list"]'))
      })

      node.find('.option').each(function (i, option) {
        const valueField = $(option).find('.next-node-id').first()
        const selectList = $(option).find('.next-node-list')

        const nextNodeId = valueField.val()

        if (validNextIds.indexOf(nextNodeId) !== -1) {
          selectList.val(nextNodeId)
        } else {
          valueField.val('')
          selectList.val('')
        }
      })
    },
    optionsForNode: function (node) {
      const nextNodes = node.nextAll(':visible')

      return $.map(nextNodes, function (nodeContainer, i) {
        node = $(nodeContainer)
        return { id: node.find('.node-slug').val(), label: node.find('.node-title').val(), kind: node.find('.node-kind').val(), name: node.find('.node-label').text() }
      })
    },
    updateNextNode: function () {
      const nextNode = $(this).val()
      $(this).closest('.option').find('.next-node-id').val(nextNode)
    }
  }
  root.Publisher.smartAnswerBuilder = smartAnswerBuilder
}).call(this)
