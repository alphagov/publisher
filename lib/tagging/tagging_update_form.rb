module Tagging
  class TaggingUpdateForm
    include ActiveModel::Model
    attr_accessor :content_id, :previous_version
    attr_accessor :topics, :organisations, :meets_user_needs, :mainstream_browse_pages, :ordered_related_items, :parent

    validate :ordered_related_items_paths_exist

    def self.build_from_publishing_api(content_id, locale)
      link_set = LinkSet.find(content_id, locale)

      new(
        content_id: content_id,
        previous_version: link_set.version,
        topics: link_set.links['topics'],
        organisations: link_set.links['organisations'],
        meets_user_needs: link_set.links['meets_user_needs'],
        mainstream_browse_pages: link_set.links['mainstream_browse_pages'],
        ordered_related_items: link_set.expanded_links['ordered_related_items'],
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
        organisations: clean_content_ids(organisations),
        meets_user_needs: clean_content_ids(meets_user_needs),
        mainstream_browse_pages: clean_content_ids(mainstream_browse_pages),
        ordered_related_items: transform_base_paths_to_content_ids(ordered_related_items),
        parent: clean_content_ids(parent),
      }
    end

  private

    def clean_content_ids(select_form_input)
      Array(select_form_input).select(&:present?)
    end

    def ordered_related_items_paths_exist
      (Array(ordered_related_items) - ordered_related_items_path_by_ids.keys).each do |missing_path|
        next if missing_path.blank?
        errors.add(:ordered_related_items, "#{missing_path} is not a known URL on GOV.UK")
      end
    end

    def ordered_related_items_path_by_ids
      @_ordered_related_items_path_by_ids ||= begin
        Services.publishing_api.lookup_content_ids(base_paths: ordered_related_items)
      end
    end

    def transform_base_paths_to_content_ids(base_paths)
      Array(base_paths).reject!(&:blank?)
      return [] if base_paths.blank?
      base_paths.map { |base_path| ordered_related_items_path_by_ids[base_path] }
    end
  end
end
