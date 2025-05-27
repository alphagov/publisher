require "csv"
require_dependency "safe_html"

class LocalService < ApplicationRecord
  validates :lgsl_code, :providing_tier, presence: true
  # rubocop/disable Rails/UniqueValidationWithoutIndex
  validates :lgsl_code, uniqueness: true
  # rubocop/enable Rails/UniqueValidationWithoutIndex
  validate :eligible_providing_tier

  def self.find_by_lgsl_code(lgsl_code)
    LocalService.where(lgsl_code:).first
  end

  def eligible_providing_tier
    providing_tiers = [%w[county unitary], %w[district unitary], %w[district unitary county]]

    return if providing_tiers.include?(providing_tier)

    errors.add(:providing_tier, "Not in list")
  end
end
