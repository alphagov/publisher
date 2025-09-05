require_dependency "part"

module Parted
  def self.included(klass)
    class_to_sym = klass.to_s.underscore.to_sym
    klass.has_many :parts, inverse_of: class_to_sym, dependent: :destroy

    klass.accepts_nested_attributes_for :parts,
                                        allow_destroy: true,
                                        reject_if: proc { |attrs| attrs["title"].blank? && attrs["body"].blank? }
    klass.after_validation :merge_embedded_parts_errors
  end

  def copy_to(new_edition)
    # If the new edition is of the same type or another type that has parts,
    # copy over the parts from this edition
    if new_edition.editionable.respond_to?(:parts)
      new_edition.editionable.parts = parts.map do |part|
        part_copy = part.dup
        part_copy.mongo_id = nil
        part_copy
      end
    end

    new_edition
  end

  def order_parts
    ordered_parts = parts.sort_by { |p| p.order || 99_999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end

  def whole_body
    parts.in_order.map { |i| %(\# #{i.title}\n\n#{i.body}) }.join("\n\n")
  end

private

  def merge_embedded_parts_errors
    return if parts.empty?

    if errors.any?
      parts_errors = parts.each_with_object({}) do |part, result|
        result["#{part.id}:#{part.order}"] = part.errors.messages if part.errors.present?
      end
      errors.delete("parts.title")
      errors.delete("parts.slug")
      errors.add(:parts, parts_errors)
    end
  end
end
