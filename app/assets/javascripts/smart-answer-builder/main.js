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
  generateJSON();
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
});
