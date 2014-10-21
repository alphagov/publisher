require 'gds_api/content_api'

class Collections
  def self.grouped_mainstream_browse_pages
    collections = make_collections_from_tags(mainstream_browse_page_tags)
    group_collections_by_parent(collections)
  end

  def self.grouped_topics
    collections = make_collections_from_tags(topic_tags)
    group_collections_by_parent(collections)
  end

private

  def self.group_collections_by_parent(collections)
    collections.select(&:parent_title).group_by(&:parent_title).sort
  end

  def self.make_collections_from_tags(tags)
    tags.map do |tag|
      OpenStruct.new(
        slug: slug_from_tag(tag),
        title: tag.title,
        parent_title: tag.parent.try(:title),
        draft?: (tag.state == "draft")
      )
    end
  end

  def self.mainstream_browse_page_tags
    content_api.tags("section", draft: true)
  end

  def self.topic_tags
    content_api.tags("specialist_sector", draft: true)
  end

  def self.content_api
    GdsApi::ContentApi.new(Plek.find("contentapi"))
  end

  def self.slug_from_tag(tag)
    URI.unescape(tag.id.match(%r{/([^/]*)\.json})[1])
  end
end
