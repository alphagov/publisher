(function() {
  "use strict";

  var root = this,
      $ = root.jQuery;
  if(typeof root.Publisher === 'undefined') { root.Publisher = {}; }

  var smartAnswerBuilder = {
    init: function() {
      smartAnswerBuilder.setEventHandlers();
      smartAnswerBuilder.reloadAllNextNodeLists();
      smartAnswerBuilder.setupInitialQuestion();
    },
    lastNodeKind: null,
    setEventHandlers: function() {
      smartAnswerBuilder.addQuestionButton().click(smartAnswerBuilder.addQuestion);
      smartAnswerBuilder.addOutcomeButton().click(smartAnswerBuilder.addOutcome);

      $('.nodes').on("change", ".node input.node-title", smartAnswerBuilder.reloadAllNextNodeLists);
      $('.nodes').on("change", ".node select.next-node-list", smartAnswerBuilder.updateNextNode);

      $(document).on('nested:fieldAdded:nodes', smartAnswerBuilder.initNode);
      $(document).on('nested:fieldRemoved:nodes', smartAnswerBuilder.reloadAllNextNodeLists);

      $(document).on('nested:fieldAdded:options', smartAnswerBuilder.initOption);
    },
    container: $('.builder-container'),
    addQuestion: function() {
      smartAnswerBuilder.lastNodeKind = "question";
    },
    addOutcome: function() {
      smartAnswerBuilder.lastNodeKind = "outcome";
    },
    addQuestionButton: function() {
      return smartAnswerBuilder.container.find('a.add-question');
    },
    addOutcomeButton: function() {
      return smartAnswerBuilder.container.find('a.add-outcome');
    },
    setupInitialQuestion: function() {
      if (smartAnswerBuilder.container.find('.node').length < 1) {
        smartAnswerBuilder.addQuestionButton().click();
      }
    },
    initNode: function(e) {
      var kind = smartAnswerBuilder.lastNodeKind;
      var node = e.field;
      smartAnswerBuilder.lastNodeKind = null;

      var indexOfKind = smartAnswerBuilder.container.find(".node."+ kind).length + 1;

      node.find('input.node-kind').val(kind);
      node.find('input.node-slug').val(nodeId(kind));

      node.find('.node-label').text(nodeLabel(kind));
      node.addClass(kind).attr('id', nodeId(kind));

      if (kind != "question") {
        node.find('.options').remove();
      } else {
        node.find('.options .add_nested_fields').click();
      }

      smartAnswerBuilder.reloadAllNextNodeLists();

      function nodeId(kind) {
        return kind + "-" + indexOfKind;
      }

      function nodeLabel(kind) {
        var capitalizedKind = kind.charAt(0).toUpperCase() + kind.slice(1);
        return capitalizedKind + " " + indexOfKind;
      }
    },
    initOption: function(e) {
      var node = $(e.field).parents(".node").first();
      smartAnswerBuilder.reloadNextNodeList(node);
    },
    reloadAllNextNodeLists: function() {
      $.each( smartAnswerBuilder.container.find('.node'), function(i,node) {
        smartAnswerBuilder.reloadNextNodeList( $(node) );
      });
    },
    reloadNextNodeList: function(node) {
      var nextNodeField = node.find('.next-node-list');
      nextNodeField.find('option:not(.default)').remove();

      $.each( smartAnswerBuilder.optionsForNode(node), function(i, x) {
        var optionLabel = x.name;
        if (x.label != '') {
          optionLabel = optionLabel + " (" + x.label + ")";
        }
        $('<option></option>').text(optionLabel).attr('value', x.id).appendTo(nextNodeField.find('optgroup[class="'+ x.kind +'-list"]'));
      });

      node.find('.option').each( function(i, option){
        var nextNodeId = $(option).find('.next-node-id').first().val();
        $(option).find('.next-node-list').val(nextNodeId);
      });
    },
    optionsForNode: function(node) {
      var nextNodes = node.nextAll(':visible');

      return $.map( nextNodes, function(nodeContainer, i) {
        node = $(nodeContainer);
        return { id: node.find('.node-slug').val(), label: node.find('.node-title').val(), kind: node.find('.node-kind').val(), name: node.find('.node-label').text() };
      });
    },
    updateNextNode: function() {
      var nextNode = $(this).val();
      $(this).parent('.option').find('.next-node-id').val(nextNode);
    },
  }
  root.Publisher.smartAnswerBuilder = smartAnswerBuilder;
}).call(this);
