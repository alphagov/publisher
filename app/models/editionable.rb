module Editionable
  extend ActiveSupport::Concern

  included do
    has_one :edition, as: :editionable, touch: true
  end
end
