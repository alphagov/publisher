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
      var index = smartAnswerBuilder.indexOfKind(kind);

      var node = e.field;
      smartAnswerBuilder.lastNodeKind = null;
      
      node.find('input.node-kind').val(kind);
      node.find('input.node-slug').val(nodeId(kind, index));
      node.find('input.node-order').val($('.node').length);

      node.find('.node-label').text(nodeLabel(kind, index));
      node.addClass(kind).attr('id', nodeId(kind, index));

      if (kind != "question") {
        node.find('.options').remove();
      } else {
        node.find('.options .add_nested_fields').click();
        node.find('input.node-title').attr('placeholder', 'The title of the question');
      }

      smartAnswerBuilder.reloadAllNextNodeLists();

      function nodeId(kind, index) {
        return kind + "-" + index;
      }

      function nodeLabel(kind, index) {
        var capitalizedKind = kind.charAt(0).toUpperCase() + kind.slice(1);
        return capitalizedKind + " " + index;
      }
    },
    indexOfKind: function(kind) {
      var kindMatch = new RegExp(kind + "-");
      var indexes = smartAnswerBuilder.container.find(".node."+ kind +" .node-slug").map( function(){
        var index = $(this).val().replace(kindMatch, "");
        return parseInt(index);
      }).get();
      if (indexes.length < 1) {
        return 1;
      } else {
        var max = Math.max.apply(null, indexes);
        return max + 1;
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

      var validNextNodes = smartAnswerBuilder.optionsForNode(node);
      var validNextIds = $.map(validNextNodes, function(n){ return n.id; });

      $.each( validNextNodes, function(i, x) {
        var optionLabel = x.name;
        if (x.label != '') {
          optionLabel = optionLabel + " (" + x.label + ")";
        }
        $('<option></option>').text(optionLabel).attr('value', x.id).appendTo(nextNodeField.find('optgroup[class="'+ x.kind +'-list"]'));
      });

      node.find('.option').each( function(i, option){
        var valueField = $(option).find('.next-node-id').first();
        var selectList = $(option).find('.next-node-list');

        var nextNodeId = valueField.val();

        if (validNextIds.indexOf(nextNodeId) != -1) {
          selectList.val(nextNodeId);
        } else {
          valueField.val("");
          selectList.val("");
        }
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
      $(this).closest('.option').find('.next-node-id').val(nextNode);
    }
  }
  root.Publisher.smartAnswerBuilder = smartAnswerBuilder;
}).call(this);
