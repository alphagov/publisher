module Editionable
  extend ActiveSupport::Concern

  included do
    has_one :edition, as: :editionable
    validates_with LinkValidator, on: :update
    validates_with SafeHtml
  end
end
