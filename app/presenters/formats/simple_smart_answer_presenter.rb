module Formats
  class SimpleSmartAnswerPresenter < EditionFormatPresenter
  private

    def schema_name
      'simple_smart_answer'
    end

    def details
      required_details
        .merge(optional_details)
        .merge(external_related_links: external_related_links)
    end

  private

    def required_details
      {
        start_button_text: edition.start_button_text,
      }
    end

    def optional_details
      {}.merge(body)
        .merge(nodes)
    end

    def body
      return {} if edition.body.nil?

      {
        body: [
          {
            content_type: "text/govspeak",
            content: @edition.body.to_s,
          }
        ]
      }
    end

    def nodes
      return {} if edition.nodes.empty?

      {
        nodes: edition.nodes.map { |n| presented_node(n) }
      }
    end

    def presented_node(node)
      {
        kind: node.kind.to_s,
        slug: node.slug.to_s,
        title: node.title.to_s,
        options: presented_node_options(node.options),
      }.merge(presented_node_body(node.body))
    end

    def presented_node_body(node_body)
      return {} unless node_body.present?

      {
        body: [
          {
            content_type: 'text/govspeak',
            content: node_body.to_s,
          }
        ],
      }
    end

    def presented_node_options(options)
      options.map { |o| presented_node_option(o) }
    end

    def presented_node_option(option)
      {
        label: option.label.to_s,
        slug: option.slug.to_s,
        next_node: option.next_node.to_s
      }
    end
  end
end
