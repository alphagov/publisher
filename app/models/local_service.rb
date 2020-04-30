require "csv"
require_dependency "safe_html"

class LocalService
  include Mongoid::Document

  field :description,    type: String
  field :lgsl_code,      type: Integer
  field :providing_tier, type: Array

  validates :lgsl_code, :providing_tier, presence: true
  validates :lgsl_code, uniqueness: true
  validates :providing_tier, inclusion: {
    in: [%w[county unitary], %w[district unitary], %w[district unitary county]],
  }

  def self.find_by_lgsl_code(lgsl_code)
    LocalService.where(lgsl_code: lgsl_code).first
  end
end
