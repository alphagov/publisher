# Linkables
#
# Note that the functionality to fetch tags from the publishing-api and
# transform them into a structure for a dropdown in a form is duplicated
# across apps like content-tagger and Whitehall.
# Example: https://github.com/alphagov/content-tagger/blob/master/lib/linkables.rb
# Once we've migrated all apps
# to use `content_id`, we may move this functionality into a gem.
module Tagging
  class Linkables
    CACHE_OPTIONS = { expires_in: 15.minutes, race_condition_ttl: 30.seconds }.freeze

    def topics
      @topics ||= for_nested_document_type("topic")
    end

    def taxons
      @taxons ||= for_document_type("taxon")
    end

    def organisations
      @organisations ||= for_document_type("organisation")
    end

    def meets_user_needs
      @meets_user_needs ||= for_document_type("need")
    end

    def mainstream_browse_pages
      @mainstream_browse_pages ||= for_nested_document_type("mainstream_browse_page")
    end

  private

    def for_document_type(document_type)
      items = get_tags_of_type(document_type)
      present_items(items)
    end

    def for_nested_document_type(document_type)
      # In Topics and Browse pages, the "internal name" is generated in the
      # form: "Parent title / Child title". Because currently we only show
      # documents on child-topic pages (like /topic/animal-welfare/pets), we
      # only allow tagging to those tags in this application. That's why we
      # filter out the top-level (which don't have the slash) topics/browse
      # pages here. This of course is temporary, until we've introduced a
      # global taxonomy that will allow editors to tag to any level.
      items = get_tags_of_type(document_type)
        .select { |item| item.fetch("internal_name").include?(" / ") }

      items = filter_browse_topics(items)

      organise_items(present_items(items))
    end

    # While we're migrating the Browse pages to topics we will briefly have a combination of the
    # two in our model. We need to filter out the pages we brought across from the results.
    def filter_browse_topics(items)
      return items if items.empty? || items.first.fetch("base_path").exclude?("/topic/")

      # Get topics that are not mainstream browse copies
      valid_topics ||= Rails.cache.fetch("valid_topics", CACHE_OPTIONS) do
        Services.publishing_api.get_content_items(document_type: "topic", per_page: 10_000, fields: %w[content_id details])["results"].select do |item|
          item.dig("details", "mainstream_browse_origin").nil?
        end
      end

      # Filter the invalid topics out of the items collection
      items.select { |item| valid_topics.any? { |topic| topic.fetch("content_id") == item.fetch("content_id") } }
    end

    def present_items(items)
      items = items.map do |item|
        title = item.fetch("internal_name")
        title = "#{title} (draft)" if item.fetch("publication_state") == "draft"

        [title, item.fetch("content_id")]
      end

      items.sort_by(&:first)
    end

    def organise_items(items)
      items.group_by { |entry| entry.first.split(" / ").first }
    end

    def get_tags_of_type(document_type)
      items = Services.publishing_api.get_linkables(document_type: document_type)
      items.select { |item| item["internal_name"] }
    end
  end
end
