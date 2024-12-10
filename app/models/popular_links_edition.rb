class PopularLinksEdition < Edition
  # field :link_items, type: Array
  validate :six_link_items_present
  validate :all_valid_urls_and_titles_are_present

  def six_link_items_present
    errors.add(:link_items, "6 links are required") if link_items.count != 6
  end

  def all_valid_urls_and_titles_are_present
    link_items.each_with_index do |item, index|
      errors.add("url#{index + 1}", "URL is required for Link #{index + 1}") unless url_present?(item)
      errors.add("title#{index + 1}", "Title is required for Link #{index + 1}") unless title_present?(item)
      errors.add("url#{index + 1}", "URL is invalid for Link #{index + 1}, all URLs should start with '/'") if url_present?(item) && url_is_not_valid_relative_url?(item[:url])
    end
  end

  def url_is_not_valid_relative_url?(url)
    !url.start_with?("/")
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

  def publish_latest
    save_draft if is_draft?
    Services.publishing_api.publish(content_id, update_type, locale:)
    # This publish_popular_links is a new workflow that was introduced for popular links.
    publish_popular_links
  end

  def save_draft
    UpdateService.call(self)
    save!
  end

  def content_id
    "ad7968d0-0339-40b2-80bc-3ea1db8ef1b7".freeze
  end

  # PopularLinks updates are going to be a major update
  # as there is no real reason for having a minor update
  def update_type
    "major".freeze
  end

  def locale
    "en".freeze
  end

  def can_delete?
    is_draft?
  end

private

  def is_draft?
    state == "draft"
  end
end
