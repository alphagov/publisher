(function() {
  "use strict";

  var root = this,
      $ = root.jQuery;
  if(typeof root.Publisher === 'undefined') { root.Publisher = {}; }

  var smartAnswerBuilder = {
    init: function() {
      smartAnswerBuilder.setEventHandlers();
    },
    lastNodeKind: null,
    setEventHandlers: function() {
      smartAnswerBuilder.addQuestionButton().click(smartAnswerBuilder.addQuestion);
      smartAnswerBuilder.addOutcomeButton().click(smartAnswerBuilder.addOutcome);

      $(document).on('nested:fieldAdded', smartAnswerBuilder.initNode);
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
    initNode: function(e) {
      var kind = smartAnswerBuilder.lastNodeKind;
      var node = e.field.find('.node');
      smartAnswerBuilder.lastNodeKind = null;

      var indexOfKind = smartAnswerBuilder.container.find(".node."+ kind).length + 1;

      node.find('input.node-kind').val(kind);
      node.find('input.node-slug').val(nodeId(kind));

      node.find('.node-label').text(nodeLabel(kind));
      node.addClass(kind).attr('id', nodeId(kind));

      if (kind != "question") {
        node.find('.options').remove();
      }

      function nodeId(kind) {
        return kind + "-" + indexOfKind;
      }

      function nodeLabel(kind) {
        var capitalizedKind = kind.charAt(0).toUpperCase() + kind.slice(1);
        return capitalizedKind + " " + indexOfKind;
      }
    }
  }
  root.Publisher.smartAnswerBuilder = smartAnswerBuilder;
}).call(this);
