class SimpleSmartAnswerEdition
  class Node < ApplicationRecord
    belongs_to :simple_smart_answer_edition, class_name: "SimpleSmartAnswerEdition"
    has_many :options, dependent: :destroy, class_name: "SimpleSmartAnswerEdition::Node::Option"

    accepts_nested_attributes_for :options, allow_destroy: true

    default_scope -> { order(order: :asc) }

    GOVSPEAK_FIELDS = [:body].freeze

    KINDS = %w[
      question
      outcome
    ].freeze

    validate :title_is_present
    validates :kind, presence: true
    validates :kind, inclusion: { in: KINDS }
    validates :slug, presence: true, format: { with: /\A[a-z0-9-]+\z/ }

    validate :outcomes_have_no_options
    validates_with SafeHtml

  private

    def outcomes_have_no_options
      errors.add(:options, "cannot be added for an outcome") if options.present? && options.any? && kind == "outcome"
    end

    def title_is_present
      errors.add(:title, "Enter a title for #{slug.humanize.gsub('-', ' ')}") if title.blank?
    end
  end
end
