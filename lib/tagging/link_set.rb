module Tagging
  class LinkSet
    attr_reader :links, :expanded_links, :version

    def self.find(content_id)
      link_set = Services.publishing_api.get_expanded_links(content_id)
      new(link_set.to_h)
    rescue GdsApi::HTTPNotFound
      new({})
    end

    def initialize(data)
      @links = extract_content_ids(data['expanded_links'] || {})
      @expanded_links = data['expanded_links'] || {}
      @version = data['version'] || 0
    end

    def extract_content_ids(expanded_links)
      expanded_links.transform_values { |v| v.collect { |h| h['content_id'] } }
    end
  end
end
