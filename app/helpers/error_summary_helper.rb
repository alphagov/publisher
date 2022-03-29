module ErrorSummaryHelper
  def errors_to_display(edition)
    case edition
    when SimpleSmartAnswerEdition
      smart_answer_errors(edition)
    when GuideEdition
      guide_errors(edition)
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

    # Errors with attributes of options or nodes will be an error for a option / node as a whole (rather than the individual field) and not helpful
    # Errors with an attribute of 'slug' will be slugs which are derived, rather than being input explicitly, so are not useful error messages
    (edition_errors + nested_errors)
      .reject { |error, _| %i[nodes options slug].include?(error.attribute) }
      .map { |error, href| [error.message, href] }
  end

  def guide_errors(guide)
    edition_errors = top_level_errors(guide)

    parts_errors = []

    guide.parts.each do |part|
      part.errors.each do |error|
        parts_errors << [error, href_for_part(part, error.attribute)]
      end
    end

    (edition_errors + parts_errors)
      .reject { |error, _| error.attribute == :parts } # Errors with attributes of parts will be an error for a part as a whole (rather than the individual field) and not helpful
      .map { |error, href| [error.message, href] }
  end

  def href_for_node(node, attribute)
    "#edition_nodes_attributes_#{node.order - 1}_#{attribute}"
  end

  def href_for_option(option, node, attribute)
    attr = attribute == :next_node ? "node" : attribute
    "#edition_nodes_attributes_#{node.order - 1}_options_attributes_#{node.options.find_index(option)}_#{attr}"
  end

  def href_for_part(part, attribute)
    "#edition_parts_attributes_#{part.guide_edition.parts.find_index(part)}_#{attribute}"
  end
end
