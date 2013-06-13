var findNode = function(type, index) {
  for(var i = 0; i < window.nodes.length; i++) {
    var c = window.nodes[i];
    if(c.type == type && c.index == index) {
      return c;
    }
  };
  return false;
};

var optionsForNode = function(index) {
  options = [];
  for(var i = 0; i < window.nodes.length; i++) {
    var current = window.nodes[i];
    if((current.type == "question" && current.index > index) || current.type == "outcome") {
      var title = (current.type == "question" ? "Question " : "Outcome ") + current.index;
      if(current.title != "") {
        title += " (" + current.title + ")";
      }
      options.push({
        type: current.type,
        key: current.type + current.index,
        title: title
      });
    }
  }
  return options;
};

var renderAll = function() {
  for(var i = 0; i < window.nodes.length; i++) {
    window.nodes[i].render();
  }
};

var generateJSON = function() {
  var SA = {};
  SA.nodes = {};
  for(var i = 0; i < window.nodes.length; i++) {
    var current = window.nodes[i];
    SA.nodes[current.type + current.index] = {
      title: current.title,
      body: current.bodyText
    };
    if(current.type === "question") {
      SA.nodes[current.type + current.index].options = {};
      for(var j = 0; j < current.options.length; j++) {
        var opt = current.options[j];
        if(opt.text != "" && opt.destination != "") {
          SA.nodes[current.type + current.index].options[opt.text] = opt.destination;
        }
      }
    }
  };
  $('#smart-answer-nodes').val(JSON.stringify(SA.nodes));
};
