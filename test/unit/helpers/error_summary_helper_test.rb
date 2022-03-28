require "test_helper"

class ErrorSummaryHelperTest < ActionView::TestCase
  include ErrorSummaryHelper

  def guide_with_title_and_parts(title, parts)
    GuideEdition.new(title: title, parts: parts, panopticon_id: "Some_id")
  end

  test "For a Guide, errors_to_display returns useful error messages and correct hrefs for invalid fields" do
    valid_part = Part.new(title: "some part", slug: "another-slug")
    invalid_part_1 = Part.new(title: "", slug: "invalid slug with spaces")
    invalid_part_2 = Part.new(title: "valid title", slug: "another invalid slug")

    guide_with_invalid_data = guide_with_title_and_parts("", [valid_part, invalid_part_1, invalid_part_2])

    guide_with_invalid_data.valid?

    expected_errors = [
      ["Enter a title", "#edition_title"],
      ["Enter a title for Part 2", "#edition_parts_attributes_1_title"],
      ["Slug can only consist of lower case characters, numbers and hyphens", "#edition_parts_attributes_1_slug"],
      ["Slug can only consist of lower case characters, numbers and hyphens", "#edition_parts_attributes_2_slug"],
    ]

    assert_equal expected_errors, errors_to_display(guide_with_invalid_data)
  end

  test "For a SimpleSmartAnswer, errors_to_display returns useful error messages and correct hrefs for invalid fields" do
    valid_outcome_node = SimpleSmartAnswerEdition::Node.new(kind: "outcome", title: "Node 1", slug: "node-1", order: 1)
    outcome_node_without_title = SimpleSmartAnswerEdition::Node.new(kind: "outcome", title: "", slug: "node-2", order: 2)

    valid_option = SimpleSmartAnswerEdition::Node::Option.new(next_node: "Node 1", label: "Some label")
    invalid_option_1 = SimpleSmartAnswerEdition::Node::Option.new(next_node: "Node 1", label: "")
    invalid_option_2 = SimpleSmartAnswerEdition::Node::Option.new(next_node: "", label: "Another label")
    question_node_with_valid_and_invalid_options = SimpleSmartAnswerEdition::Node.new(kind: "question", title: "Node 3", slug: "node-3", order: 3, options: [valid_option, invalid_option_1, invalid_option_2])

    simple_smart_answer = SimpleSmartAnswerEdition.new(title: "", panopticon_id: "Some_id", nodes: [valid_outcome_node, outcome_node_without_title, question_node_with_valid_and_invalid_options])

    simple_smart_answer.valid?

    expected_errors = [
      ["Enter a title", "#edition_title"],
      ["Enter a title for Node 2", "#edition_nodes_attributes_1_title"],
      ["Enter a label for Node 3, Option 2", "#edition_nodes_attributes_2_options_attributes_1_label"],
      ["Select a node for Node 3, Option 3", "#edition_nodes_attributes_2_options_attributes_2_node"],
    ]

    assert_equal expected_errors, errors_to_display(simple_smart_answer)
  end

  test "For an Edition without nested fields, errors_to_display returns useful error messages and correct hrefs for invalid fields" do
    invalid_edition = LocalTransactionEdition.new(title: "", panopticon_id: "Some_id", lgil_code: 1.11)

    invalid_edition.valid?

    expected_errors = [
      ["Enter a title", "#edition_title"],
      ["Enter a LGSL code", "#edition_lgsl_code"],
      ["LGIL code can only be a whole number between 0 and 999", "#edition_lgil_code"],
    ]

    assert_equal expected_errors, errors_to_display(invalid_edition)
  end
end
