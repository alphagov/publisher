module Tagging
  class LinkSet
    attr_reader :links, :version

    def self.find(content_id)
      link_set = Services.publishing_api.get_links(content_id)
      new(link_set.to_h)
    end

    def initialize(data)
      @links = data['links'] || {}
      @version = data['version'] || 0
    end
  end
end
