class PopularLinksEdition < Edition
  field :link_items, type: Array
  validate :six_link_items_present?
  validate :all_urls_and_titles_are_present?

  def six_link_items_present?
    errors.add(:link_items, "6 links are required") if link_items.count != 6
  end

  def all_urls_and_titles_are_present?
    link_items.each_with_index do |item, index|
      errors.add(:item, "A URL is required for Link #{index + 1}") unless item.key?(:url)
      errors.add(:item, "A Title is required for Link #{index + 1}") unless item.key?(:title)
    end
  end
end
