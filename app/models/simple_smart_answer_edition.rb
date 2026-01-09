class SimpleSmartAnswerEdition < ApplicationRecord
  include Editionable

  validates :start_button_text, presence: true

  has_many :nodes, class_name: "SimpleSmartAnswerEdition::Node", dependent: :destroy

  accepts_nested_attributes_for :nodes, allow_destroy: true

  delegate :title, to: :edition

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    parts = body == "" ? [] : [body]
    unless nodes.nil?
      nodes.each do |node|
        parts << if node.kind == "question"
                   question(node)
                 elsif node.kind == "outcome"
                   outcome(node)
                 end
      end
    end
    parts.join("\n\n\n")
  end

  def copy_to(other)
    if other.is_a?(SimpleSmartAnswerEdition)
      other.nodes = nodes.map do |node|
        new_node = node.dup
        new_node.mongo_id = nil
        new_node.options = node.options.map do |option|
          new_option = option.dup
          new_option.mongo_id = nil

          new_option
        end

        new_node
      end
    end
  end

  # Workaround mongoid conflicting mods error
  # See https://jira.mongodb.org/browse/MONGOID-1220
  # Override update so that nested nodes are updated individually.
  # This get around the problem of mongoid issuing a query with conflicting modifications
  # to the same document.
  alias_method :original_update, :update

  # Any validation errors are eventually checked by the caller
  # rubocop:disable Rails/SaveBang
  def update(attributes)
    nodes_attrs = attributes.delete(:nodes_attributes)
    if nodes_attrs
      nodes_attrs.each_value do |node_attrs|
        # as this isn't a Hash
        node_id = node_attrs["id"]
        if node_id
          node = nodes.find(node_id)
          if destroy_in_attrs?(node_attrs)
            node.destroy
          else
            node.update(node_attrs)
          end
        else
          nodes << Node.new(node_attrs) unless destroy_in_attrs?(node_attrs)
        end
      end
    end

    original_update(attributes)
  end
  # rubocop:enable Rails/SaveBang

  def initial_node
    nodes.first
  end

  def destroy_in_attrs?(attrs)
    attrs.delete("_destroy") == "1"
  end

  def generate_mermaid
    parts = ["%%{ init: {\n'theme': 'base',\n'themeVariables': {\n    " \
               "'background': '#FFFFFF',\n    'primaryTextColor': '#0B0C0C',\n    " \
               "'lineColor': '#0b0c0c',\n    'fontSize': '23.75px' } } }%%\nflowchart TD"]
    parts << "accTitle: #{title}\naccDescr: A flowchart for the #{title} smart answer\nAA[Start]:::start"
    if nodes.present?
      parts << "AA---Q#{nodes.first.slug.split('-')[1]}"
      nodes.each do |node|
        parts << if node.kind == "question"
                   mermaid_question(node)
                 elsif node.kind == "outcome"
                   mermaid_outcome(node)
                 end
      end
    end
    parts << "classDef answer fill: #F3F2F1, stroke:#505A5F;\nclassDef outcome fill: #6FA4D2" \
      "\nclassDef question fill: #B1B4B6, stroke:#505A5F;\nclassDef start fill:#00703c,color: #ffffff"
    parts.join("\n")
  end

private

  def question(node)
    part = ["#{node.slug.titleize}\n#{node.title}\n"]
    part << node.body.to_s unless node.body == ""
    part << ""
    node.options.each.with_index(1) do |option, index|
      part << "Answer #{index}\n#{option.label}"
      title = nodes.select { |single_node| single_node["slug"] == option.next_node }[0].title.to_s
      next_node_title, next_node_number = option.next_node.split("-")
      part << "Next question for user: #{next_node_title.capitalize} #{next_node_number} (#{title})\n"
    end
    part.join("\n")
  end

  def outcome(node)
    body = node.body == "" ? "" : "\n#{node.body}"
    "#{node.slug.titleize}\n#{node.title}#{body}"
  end

  def mermaid_question(node)
    question_node_id = node.slug.split("-")[1]
    part = ["Q#{question_node_id}[\"`Q#{question_node_id}. #{node.title}`\"]:::question"]
    node.options.each.with_index(1) do |option, index|
      answer_node_id = "Q#{question_node_id}A#{index}"
      next_node_title, next_node_number = option.next_node.split("-")
      part << "Q#{question_node_id}---#{answer_node_id}\n" \
        "#{answer_node_id}([\"`A#{index}. #{option.label}`\"]):::answer\n" \
        "#{answer_node_id}-->#{next_node_title[0].upcase}#{next_node_number}\n"
    end
    part.join("\n")
  end

  def mermaid_outcome(node)
    outcome_node_id = node.slug.split("-")[1]
    "O#{outcome_node_id}{{\"`O#{outcome_node_id}. #{node.title}`\"}}:::outcome"
  end
end
