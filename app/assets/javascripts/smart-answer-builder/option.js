var Option = function(opts) {
  this.text = "";
  this.destination = "";
  this.index = ++window.optionIndex;
}

Option.prototype = {
  render: function(opts) {
    options = [];
    for(var i = 0; i < opts.length; i++) {
      if(this.destination == opts[i].key) {
        opts[i].selected = "selected";
      }
      options.push(opts[i]);
    };
    var questions = $.grep(options, function(elem) {
      return elem.type === "question";
    });
    var outcomes = $.grep(options, function(elem) {
      return elem.type === "outcome";
    });
    return JST.option({ 
      option_questions: questions,
      option_outcomes: outcomes,
      index: this.index,
      text: this.text 
    });
  },
  bindInputs: function() {
    var self = this;
    var dom = $("#option-" + this.index);
    dom.find("input[type='text']").on("change", function(e) {
      e.preventDefault();
      self.text = this.value;
    });
    dom.find("select").on("blur", function(e) {
      e.preventDefault();
      self.destination = this.value;
    });
  }
};

