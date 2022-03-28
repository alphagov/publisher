module ErrorSummaryHelper
  def errors_to_display(edition)
    errors_with_hrefs = case edition
                        when SimpleSmartAnswerEdition
                          return_smart_answer_errors_and_hrefs(edition)
                        when GuideEdition
                          return_guide_errors_and_hrefs(edition)
                        else
                          return_top_level_errors_and_hrefs(edition)
                        end
    errors_with_hrefs.map { |error, href| [error.message, href] }
  end

private

  def return_smart_answer_errors_and_hrefs(smart_answer)
    all_errors_and_hrefs = return_top_level_errors_and_hrefs(smart_answer) +
      get_node_errors_and_hrefs(smart_answer.nodes) +
      get_option_errors_and_href(smart_answer.nodes.flat_map(&:options))

    # Here we reject any errors with a type of 'invalid' as these will be because of invalid nodes or options and the useful error message will exist at that level
    all_errors_and_hrefs.reject { |error, _| error.type == :invalid }
  end

  def return_guide_errors_and_hrefs(guide)
    all_errors_and_hrefs = return_top_level_errors_and_hrefs(guide) + get_part_errors_and_href(guide.parts)

    # Reject errors with an attribute of 'parts' as these are because of the nested structure of guides and will be duplicated so not helpful
    all_errors_and_hrefs.reject { |error, _| error.attribute == :parts }
  end

  def return_top_level_errors_and_hrefs(edition)
    edition.errors.map { |error| [error, "#edition_#{error.attribute}"] }
  end

  def get_node_errors_and_hrefs(nodes)
    href_constructor = proc do |node, attribute|
      "#edition_nodes_attributes_#{node.order - 1}_#{attribute}"
    end
    get_errors_and_hrefs_from_nested_objects(nodes, &href_constructor)
  end

  def get_option_errors_and_href(options)
    href_constructor = proc do |option, attribute|
      node = option.node
      attr = attribute == :next_node ? "node" : attribute
      "#edition_nodes_attributes_#{node.order - 1}_options_attributes_#{node.options.find_index(option)}_#{attr}"
    end
    get_errors_and_hrefs_from_nested_objects(options, &href_constructor)
  end

  def get_part_errors_and_href(parts)
    href_constructor = proc do |part, attribute|
      "#edition_parts_attributes_#{part.guide_edition.parts.find_index(part)}_#{attribute}"
    end
    get_errors_and_hrefs_from_nested_objects(parts, &href_constructor)
  end

  def get_errors_and_hrefs_from_nested_objects(nested_objects, &href_constructor)
    nested_objects
      .select { |object| object.errors.present? }
      .flat_map { |object| object.errors.map { |error| [error, href_constructor.call(object, error.attribute)] } }
  end
end
