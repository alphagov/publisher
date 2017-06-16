require_dependency "part"

module Parted
  def self.included(klass)
    klass.embeds_many :parts
    klass.accepts_nested_attributes_for :parts, allow_destroy: true,
      reject_if: proc { |attrs| attrs["title"].blank? && attrs["body"].blank? }
    klass.after_validation :merge_embedded_parts_errors
  end

  def build_clone(target_class = nil)
    new_edition = super

    # If the new edition is of the same type or another type that has parts,
    # copy over the parts from this edition
    if target_class.nil? || target_class.include?(Parted)
      new_edition.parts = self.parts.map(&:dup)
    end

    new_edition
  end

  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end

  def whole_body
    self.parts.in_order.map { |i| %(\# #{i.title}\n\n#{i.body}) }.join("\n\n")
  end

private

  def merge_embedded_parts_errors
    return if parts.empty?

    if errors.delete(:parts) == ["is invalid"]
      parts_errors = parts.inject({}) do |result, part|
        result["#{part._id}:#{part.order}"] = part.errors.messages if part.errors.present?
        result
      end
      errors.add(:parts, parts_errors)
    end
  end
end
