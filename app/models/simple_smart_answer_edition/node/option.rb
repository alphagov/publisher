require "edition"

class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      include Mongoid::Document

      embedded_in :node, class_name: "SimpleSmartAnswerEdition::Node"

      field :label, type: String
      field :slug, type: String
      field :next_node, type: String
      field :order, type: Integer

      default_scope lambda { order_by(order: :asc) }

      validates :label, :next_node, presence: true
      validates :slug, format: { with: /\A[a-z0-9-]+\z/ }

      before_validation :populate_slug

    private

      def populate_slug
        if label.present? && !slug_changed?
          self.slug = ActiveSupport::Inflector.parameterize(label)
        end
      end
    end
  end
end
