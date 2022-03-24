module ErrorSummaryHelper
  # -> Array[(error, href)]
  # TODO different return type? Normally here I'd use a list of tuples, but don't know what the ruby equivalent is
  def errors_to_display_hash(edition)
    errors_with_hrefs = case edition
                        when SimpleSmartAnswerEdition
                          return_smart_answer_errors_and_hrefs(edition)
                        when GuideEdition
                          return_guide_errors_and_hrefs(edition)
                        else
                          return_top_level_errors_and_hrefs(edition)
                        end
    errors_with_hrefs.transform_keys(&:message)
  end

private

  def return_smart_answer_errors_and_hrefs(smart_answer)
    all_errors_and_hrefs = return_top_level_errors_and_hrefs(smart_answer)
                             .merge(get_node_errors_and_href_hash(smart_answer.nodes))
                             .merge(get_option_errors_and_href_hash(smart_answer.nodes.flat_map(&:options)))

    all_errors_and_hrefs.reject { |error, _| error.type == :invalid }
  end

  def return_guide_errors_and_hrefs(guide)
    all_errors_and_hrefs = return_top_level_errors_and_hrefs(guide)
                             .merge(get_part_errors_and_href_hash(guide.parts))

    all_errors_and_hrefs.reject { |error, _| error.type == :invalid || error.attribute == :parts }
  end

  def return_top_level_errors_and_hrefs(edition)
    edition.errors.index_with { |error| "#edition_#{error.attribute}" }
  end

  def get_node_errors_and_href_hash(nodes)
    href_constructor = proc do |node, attribute|
      "#edition_nodes_attributes_#{node.order - 1}_#{attribute}"
    end
    get_errors_and_hrefs_from_objects(nodes, &href_constructor)
  end

  def get_option_errors_and_href_hash(options)
    href_constructor = proc do |option, attribute|
      node = option.node
      attr = attribute == :next_node ? "node" : attribute
      "#edition_nodes_attributes_#{node.order - 1}_options_attributes_#{node.options.find_index(option)}_#{attr}"
    end
    get_errors_and_hrefs_from_objects(options, &href_constructor)
  end

  def get_part_errors_and_href_hash(parts)
    href_constructor = proc do |part, attribute|
      "#edition_parts_attributes_#{part.guide_edition.parts.find_index(part)}_#{attribute}"
    end
    get_errors_and_hrefs_from_objects(parts, &href_constructor)
  end

  def get_errors_and_hrefs_from_objects(nested_objects, &href_constructor)
    nested_objects
      .select { |object| object.errors.present? }
      .flat_map { |object| object.errors.map { |error| [error, href_constructor.call(object, error.attribute)] } }
      .to_h
  end
end
