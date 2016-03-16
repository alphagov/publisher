class EditionLinksPresenter
  def initialize(edition)
    @edition = edition
  end

  def payload
    all_paths = browse_pages + topics
    if all_paths.empty?
      content_ids_by_path = {}
    else
      content_ids_by_path = fetch_content_ids(all_paths)
    end

    {
      links: {
        mainstream_browse_pages: browse_pages.map { |base_path| content_ids_by_path.fetch(base_path) },
        topics: topics.map { |base_path| content_ids_by_path.fetch(base_path) },
      }
    }
  end

private

  def browse_pages
    @edition.browse_pages.map { |slug| "/browse/#{slug}" }
  end

  def topics
    (primary_topic + @edition.additional_topics).map { |slug| "/topic/#{slug}" }
  end

  def primary_topic
    [@edition.primary_topic].select(&:present?)
  end

  def fetch_content_ids(base_paths)
    Services.publishing_api.lookup_content_ids(base_paths: base_paths)
  end
end
