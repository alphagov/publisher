module Tagging
  class TaggingUpdateForm
    include ActiveModel::Model
    attr_accessor :content_id, :previous_version, :tagging_type, :organisations, :mainstream_browse_pages, :ordered_related_items, :parent, :ordered_related_items_destroy

    validate :ordered_related_items_paths_exist

    def self.build_from_submitted_form(tagging_update_params)
      new(
        content_id: tagging_update_params["content_id"],
        previous_version: tagging_update_params["previous_version"],
        organisations: tagging_update_params["organisations"],
        meets_user_needs: tagging_update_params["meets_user_needs"],
        mainstream_browse_pages: tagging_update_params["mainstream_browse_pages"],
        ordered_related_items: tagging_update_params["ordered_related_items"],
        ordered_related_items_destroy: tagging_update_params["ordered_related_items_destroy"],
        parent: tagging_update_params["parent"],
      )
    end

    def self.build_from_publishing_api(content_id, locale)
      link_set = LinkSet.find(content_id, locale)

      new(
        content_id:,
        previous_version: link_set.version,
        organisations: link_set.links["organisations"],
        mainstream_browse_pages: link_set.links["mainstream_browse_pages"],
        ordered_related_items: link_set.expanded_links["ordered_related_items"],
        parent: link_set.links["parent"],
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
        organisations: clean_content_ids(organisations),
        mainstream_browse_pages: clean_content_ids(mainstream_browse_pages),
        ordered_related_items: transform_base_paths_to_content_ids(remove_deleted_items(ordered_related_items, ordered_related_items_destroy)),
        parent: clean_content_ids(parent),
      }
    end

  private

    def clean_content_ids(select_form_input)
      Array(select_form_input).select(&:present?)
    end

    def transform_base_paths_to_content_ids(base_paths)
      base_paths.map { |base_path| ordered_related_items_path_by_ids[base_path] }
    end

    def ordered_related_items_paths_exist
      (Array(ordered_related_items) - ordered_related_items_path_by_ids.keys).each do |missing_path|
        next if missing_path.blank?

        errors.add(:ordered_related_items, "#{missing_path} is not a known URL on GOV.UK, check URL or path is correctly entered.")
      end
    end

    def ordered_related_items_path_by_ids
      @ordered_related_items_path_by_ids ||= Services.publishing_api.lookup_content_ids(base_paths: ordered_related_items)
    end

    def remove_deleted_items(ordered_related_items, ordered_related_items_destroy)
      base_paths = []

      unless ordered_related_items.nil?
        ordered_related_items.each_with_index do |item, index|
          unless ordered_related_items_destroy&.include?(index.to_s)
            base_paths << item
          end
        end
      end

      Array(base_paths).reject!(&:blank?)

      base_paths
    end
  end
end
