require "edition"

class SimpleSmartAnswerEdition < Edition
  class Node
    include Mongoid::Document
    embedded_in :edition, class_name: "SimpleSmartAnswerEdition"
    embeds_many :options, class_name: "SimpleSmartAnswerEdition::Node::Option"

    accepts_nested_attributes_for :options, allow_destroy: true

    field :slug, type: String
    field :title, type: String
    field :body, type: String
    field :order, type: Integer
    field :kind, type: String

    default_scope lambda { order_by(order: :asc) }

    GOVSPEAK_FIELDS = [:body].freeze

    KINDS = %w(
question
outcome
).freeze

    validates :title, :kind, presence: true
    validates :kind, inclusion: { in: KINDS }
    validates :slug, presence: true, format: { with: /\A[a-z0-9-]+\z/ }

    validate :outcomes_have_no_options
    validates_with SafeHtml

  private

    def outcomes_have_no_options
      errors.add(:options, "cannot be added for an outcome") if options.present? && options.any? && kind == "outcome"
    end
  end
end
