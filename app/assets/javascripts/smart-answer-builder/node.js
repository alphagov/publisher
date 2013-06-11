
var Node = function(opts) {
  this.title = "";
  this.bodyText = "";
  this.type = opts.type || "question";
  if(this.type == "question") {
    this.index = ++window.questionIndex;
  } else {
    this.index = ++window.outcomeIndex;
  }
  this.options = [new Option()];
};

Node.prototype = {
  render: function() {
    $("#" + this.type + "-" + this.index).remove();
    var options = optionsForNode(this.index);
    var renderedOptions = [];
    for(var i = 0; i < this.options.length; i++) {
      renderedOptions.push(this.options[i].render(optionsForNode(this.index)));
    }

    var temp = this.type == "question" ? JST.question : JST.outcome;
    var html = temp({
      number: this.index,
      notFirstQuestion: this.index > 1,
      type: this.type,
      title: this.title,
      desc: this.bodyText,
      options: renderedOptions.join("\n")
    });


    $("#question-placeholder").before(html);
    this.domRef = $("#" + this.type + "-" + this.index);
    this.bindInputs();
  },
  bindInputs: function() {
    for(var i = 0; i < this.options.length; i++) {
      this.options[i].bindInputs();
    }
    var self = this;
    this.domRef.find("input[type='text']").on("change", function() {
      if(this.name === "title") {
        self.title = this.value;
      } else if(this.name === "description") {
        self.bodyText = this.value;
      }
      for(var i = 0; i < window.nodes.length; i++) {
        window.nodes[i].render();
      }
    });
  }
}
