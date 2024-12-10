require "edition"

class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      # include Mongoid::Document

      has_many :node, class_name: "SimpleSmartAnswerEdition::Node"

      field :label, type: String
      field :slug, type: String
      field :next_node, type: String
      field :order, type: Integer

      default_scope -> { order_by(order: :asc) }

      validate :validate_label_is_present
      validate :validate_node_is_selected
      validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "Slug can only consist of lower case characters, numbers and hyphens" }

      before_validation :populate_slug

    private

      def populate_slug
        if label.present? && !slug_changed?
          self.slug = ActiveSupport::Inflector.parameterize(label)
        end
      end

      def question_number_string
        node.slug.humanize.gsub("-", " ")
      end

      def option_number_string
        "Option #{node.options.find_index(self) + 1}"
      end

      def validate_label_is_present
        errors.add(:label, "Enter a label for #{question_number_string}, #{option_number_string}") if label.blank?
      end

      def validate_node_is_selected
        errors.add(:next_node, "Select a node for #{question_number_string}, #{option_number_string}") if next_node.blank?
      end
    end
  end
end
