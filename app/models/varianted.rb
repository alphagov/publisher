require_dependency "variant"

module Varianted
  def self.included(klass)
    klass.embeds_many :variants
    klass.accepts_nested_attributes_for :variants, allow_destroy: true,
                                                   reject_if: proc { |attrs| attrs["title"].blank? && attrs["slug"].blank? }
    klass.after_validation :merge_embedded_variants_errors
  end

  def build_clone(target_class = nil)
    new_edition = super

    # If the new edition is of the same type or another type that has variants,
    # copy over the variants from this edition
    if target_class.nil? || target_class.include?(Varianted)
      new_edition.variants = variants.map(&:dup)
    end

    new_edition
  end

  def order_variants
    ordered_variants = variants.sort_by { |p| p.order || 99999 }
    ordered_variants.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end

private

  def merge_embedded_variants_errors
    return if variants.empty?

    if errors.delete(:variants) == ["is invalid"]
      variants_errors = variants.each_with_object({}) do |variant, result|
        result["#{variant._id}:#{variant.order}"] = variant.errors.messages if variant.errors.present?
      end
      errors.add(:variants, variants_errors)
    end
  end
end
