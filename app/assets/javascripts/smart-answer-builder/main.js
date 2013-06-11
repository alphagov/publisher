window.questionIndex = 0;
window.outcomeIndex = 0;
window.optionIndex = 0;
window.nodes = [];

$(function() {
  var JST = {};
  JST.question = Handlebars.compile($("#question_template").html());
  JST.outcome = Handlebars.compile($("#outcome_template").html());
  JST.option = Handlebars.compile($("#option_template").html());
  window.JST = JST;
});

var init = function() {
  var n = new Node({
    type: "question"
  });
  n.render();
  window.nodes.push(n);
};

$(init);


$(function() {

  $(".add-question").on("click", function(e) {
    e.preventDefault();
    var n = new Node({
      type: "question"
    });
    window.nodes.push(n);
    renderAll();
  });

  $(".add-outcome").on("click", function(e) {
    e.preventDefault();
    var n = new Node({
      type: "outcome"
    });
    window.nodes.push(n);
    renderAll();
  });

  $("body").on("click", ".add-new-option", function(e) {
    var parent = $(this).parents(".row").get(0).id;
    var currentNode = findNode("question", parent.split("-")[1]);
    currentNode.options.push(new Option());
    e.preventDefault();
    renderAll();
  });

  $(".generateJSON").on("click", function() {
    var SA = {};
    SA.title = $("input[name='main-title']")[0].value;
    SA.description = $("textarea[name='main-desc']")[0].value;
    SA.nodes = {};
    for(var i = 0; i < window.nodes.length; i++) {
      var current = window.nodes[i];
      SA.nodes[current.type + current.index] = {
        title: current.title,
        desc: current.bodyText
      };
      console.log(current.type);
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
    $(".json-resp").remove();
    $(this).after($("<textarea></textarea>", {
      "class": "span12 json-resp",
      "height": "300px"
    }).val(JSON.stringify(SA, null, 4)).wrap("<div />", {
      "class": "row"
    }));
  });
});
