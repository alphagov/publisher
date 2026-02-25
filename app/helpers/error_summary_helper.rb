module ErrorSummaryHelper
  def errors_to_display(edition)
    case edition.editionable
    when SimpleSmartAnswerEdition
      smart_answer_errors(edition)
    else
      edition_errors(edition)
    end
  end

private

  def edition_errors(edition)
    top_level_errors(edition).map { |error, href| [error.message, href] }
  end

  def top_level_errors(edition)
    edition.errors.map { |error| [error, "#edition_#{error.attribute}"] }
  end

  def smart_answer_errors(smart_answer)
    edition_errors = top_level_errors(smart_answer)

    nested_errors = []

    smart_answer.nodes.each do |node|
      node.errors.each do |error|
        nested_errors << [error, href_for_node(node, error.attribute)]
      end

      node.options.each do |option|
        option.errors.each do |error|
          nested_errors << [error, href_for_option(option, node, error.attribute)]
        end
      end
    end

    combined_errors = edition_errors + nested_errors
    repeated_errors = []

    combined_errors.each do |error|
      repeated_errors << error unless
        SimpleSmartAnswerEdition.column_names.include?(error[0].attribute.to_s) ||
          SimpleSmartAnswerEdition::Node.column_names.include?(error[0].attribute.to_s) ||
          SimpleSmartAnswerEdition::Node::Option.column_names.include?(error[0].attribute.to_s)
    end

    combined_errors -= repeated_errors
    # Errors with attributes of options or nodes will be an error for a option / node as a whole (rather than the individual field) and not helpful
    # Errors with an attribute of 'slug' will be slugs which are derived, rather than being input explicitly, so are not useful error messages
    combined_errors
      .reject { |error, _| %i[nodes options slug].include?(error.attribute) }
      .map { |error, href| [error.message, href] }
  end

  def href_for_node(node, attribute)
    "#edition_nodes_attributes_#{node.order - 1}_#{attribute}"
  end

  def href_for_option(option, node, attribute)
    attr = attribute == :next_node ? "node" : attribute
    "#edition_nodes_attributes_#{node.order - 1}_options_attributes_#{node.options.find_index(option)}_#{attr}"
  end
end
