class PopularLinksEdition < Edition
  field :link_items, type: Array
  validate :six_link_items_present
  validate :all_valid_urls_and_titles_are_present

  def six_link_items_present
    errors.add(:link_items, "6 links are required") if link_items.count != 6
  end

  def all_valid_urls_and_titles_are_present
    link_items.each_with_index do |item, index|
      errors.add(:Url, "is required for Link #{index + 1}") unless url_present?(item)
      errors.add(:Title, "is required for Link #{index + 1}") unless title_present?(item)
      errors.add(:Url, "is invalid for Link #{index + 1}") if url_present?(item) && url_has_spaces_or_has_no_dot?(item[:url])
    end
  end

  def url_has_spaces_or_has_no_dot?(url)
    url.include?(" ") || url.exclude?(".")
  end

  def title_present?(item)
    item.key?(:title) && !item[:title].empty?
  end

  def url_present?(item)
    item.key?(:url) && !item[:url].empty?
  end

  def create_draft_popular_links_from_last_record
    last_popular_links = PopularLinksEdition.last
    popular_links = PopularLinksEdition.new(title: last_popular_links.title, link_items: last_popular_links.link_items, version_number: last_popular_links.version_number.next)
    popular_links.save!
    popular_links
  end
end
