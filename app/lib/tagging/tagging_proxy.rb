# frozen_string_literal: true

module Tagging
  class TaggingProxy
    include ActiveModel::Model

    def publish_breadcrumb!(content_id, locale, breadcrumb, previous_version)
      link_set = Tagging::LinkSet.find(content_id, locale)

      Services.publishing_api.patch_links(
        content_id,
        links: {
          organisations: link_set.links["organisations"] || [],
          mainstream_browse_pages: link_set.links["mainstream_browse_pages"] || [],
          ordered_related_items: extract_content_ids(link_set.expanded_links["ordered_related_items"]),
          parent: breadcrumb,
        },
        previous_version: previous_version.to_i,
      )
    end

  private

    def extract_content_ids(linked_items)
      return [] unless linked_items

      linked_items.map { |item| item["content_id"] }
    end
  end
end
