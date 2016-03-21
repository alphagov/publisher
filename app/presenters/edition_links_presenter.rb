class EditionLinksPresenter
  def initialize(edition)
    @edition = edition
  end

  def payload
    {
      links: {
        mainstream_browse_pages: mainstream_browse_pages_content_ids,
        parent: parent_content_ids,
        topics: topics_content_ids,
      }
    }
  end

private

  def mainstream_browse_pages_content_ids
    browse_pages_base_paths.map { |base_path| content_ids_by_path.fetch(base_path) }
  end

  def parent_content_ids
    Array.wrap(mainstream_browse_pages_content_ids.first)
  end

  def topics_content_ids
    topics_base_paths.map { |base_path| content_ids_by_path.fetch(base_path) }
  end

  def browse_pages_base_paths
    @edition.browse_pages.map { |slug| "/browse/#{slug}" }
  end

  def topics_base_paths
    primary_topic = Array.wrap(@edition.primary_topic)
    (primary_topic + @edition.additional_topics).map { |slug| "/topic/#{slug}" }
  end

  def content_ids_by_path
    @content_ids_by_path ||= begin
      all_paths = browse_pages_base_paths + topics_base_paths

      if all_paths.empty?
        {}
      else
        fetch_content_ids(all_paths)
      end
    end
  end

  def fetch_content_ids(base_paths)
    Services.publishing_api.lookup_content_ids(base_paths: base_paths)
  end
end
