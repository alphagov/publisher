module Tagging
  class TaggingUpdateForm
    include ActiveModel::Model
    attr_accessor :content_id, :previous_version
    attr_accessor :topics, :mainstream_browse_pages, :parent

    def self.build_from_publishing_api(content_id)
      link_set = LinkSet.find(content_id)

      new(
        content_id: content_id,
        previous_version: link_set.version,
        topics: link_set.links['topics'],
        mainstream_browse_pages: link_set.links['mainstream_browse_pages'],
        parent: link_set.links['parent'],
      )
    end

    def publish!
      Services.publishing_api.patch_links(
        content_id,
        links: links_payload,
        previous_version: previous_version.to_i,
      )
    end

    def links_payload
      {
        topics: clean_content_ids(topics),
        mainstream_browse_pages: clean_content_ids(mainstream_browse_pages),
        parent: clean_content_ids(parent),
      }
    end

  private

    def clean_content_ids(select_form_input)
      Array(select_form_input).select(&:present?)
    end
  end
end
