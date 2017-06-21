require "edition"
require_dependency 'simple_smart_answer_edition/node'
require_dependency 'simple_smart_answer_edition/node/option'

class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :body,              type: String
  field :start_button_text, type: String, default: "Start now"

  validates_presence_of :start_button_text

  embeds_many :nodes, class_name: "SimpleSmartAnswerEdition::Node"

  accepts_nested_attributes_for :nodes, allow_destroy: true

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    parts = [body]
    unless nodes.nil?
      parts += nodes.map { |node| "#{node.kind}: #{node.title} \n\n #{node.body}" }
    end
    parts.join("\n\n\n")
  end

  def build_clone(target_class = nil)
    new_edition = super(target_class)

    if new_edition.is_a?(SimpleSmartAnswerEdition)
      self.nodes.each { |n| new_edition.nodes << n.clone }
    end

    new_edition
  end


  # Workaround mongoid conflicting mods error
  # See https://jira.mongodb.org/browse/MONGOID-1220
  # Override update_attributes so that nested nodes are updated individually.
  # This get around the problem of mongoid issuing a query with conflicting modifications
  # to the same document.
  alias_method :original_update_attributes, :update_attributes

  def update_attributes(attributes)
    nodes_attrs = attributes.delete(:nodes_attributes)
    if nodes_attrs
      nodes_attrs.each do |_index, node_attrs|
        node_id = node_attrs['id']
        if node_id
          node = nodes.find(node_id)
          if destroy_in_attrs?(node_attrs)
            node.destroy
          else
            node.update_attributes(node_attrs)
          end
        else
          nodes << Node.new(node_attrs) unless destroy_in_attrs?(node_attrs)
        end
      end
    end

    original_update_attributes(attributes)
  end

  def initial_node
    self.nodes.first
  end

  def destroy_in_attrs?(attrs)
    attrs.delete('_destroy') == '1'
  end
end
