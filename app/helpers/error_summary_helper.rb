module ErrorSummaryHelper
  def errors_to_display(edition)
    errors_with_hrefs = case edition
                        when SimpleSmartAnswerEdition
                          smart_answer_errors(edition)
                        when GuideEdition
                          guide_errors(edition)
                        else
                          edition_errors(edition)
                        end
    errors_with_hrefs.map { |error, href| [error.message, href] }
  end

private

  def smart_answer_errors(smart_answer)
    all_errors_and_hrefs = edition_errors(smart_answer) +
      get_node_errors_and_hrefs(smart_answer.nodes) +
      get_option_errors(smart_answer.nodes.flat_map(&:options))

    # Reject errors with an attribute of 'nodes' or 'options' as these are because of the nested structure of guides and will be duplicated so not helpful
    # Errors with an attribute of 'slug' will be slugs which are derived, rather than being input explicitly, so are not useful error messages
    all_errors_and_hrefs.reject { |error, _| %i[nodes options slug].include?(error.attribute) }
  end

  def guide_errors(guide)
    all_errors_and_hrefs = edition_errors(guide) + get_part_errors(guide.parts)

    # Reject errors with an attribute of 'parts' as these are because of the nested structure of guides and will be duplicated so not helpful
    all_errors_and_hrefs.reject { |error, _| error.attribute == :parts }
  end

  def edition_errors(edition)
    edition.errors.map { |error| [error, "#edition_#{error.attribute}"] }
  end

  def get_node_errors_and_hrefs(nodes)
    href_constructor = proc do |node, attribute|
      "#edition_nodes_attributes_#{node.order - 1}_#{attribute}"
    end
    errors_from_nested_objects(nodes, &href_constructor)
  end

  def get_option_errors(options)
    href_constructor = proc do |option, attribute|
      node = option.node
      attr = attribute == :next_node ? "node" : attribute
      "#edition_nodes_attributes_#{node.order - 1}_options_attributes_#{node.options.find_index(option)}_#{attr}"
    end
    errors_from_nested_objects(options, &href_constructor)
  end

  def get_part_errors(parts)
    href_constructor = proc do |part, attribute|
      "#edition_parts_attributes_#{part.guide_edition.parts.find_index(part)}_#{attribute}"
    end
    errors_from_nested_objects(parts, &href_constructor)
  end

  def errors_from_nested_objects(nested_objects, &href_constructor)
    nested_objects
      .select { |object| object.errors.present? }
      .flat_map { |object| object.errors.map { |error| [error, href_constructor.call(object, error.attribute)] } }
  end
end
