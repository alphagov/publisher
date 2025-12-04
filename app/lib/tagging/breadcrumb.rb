# frozen_string_literal: true

module Tagging
  class Breadcrumb
    include ActiveModel::Model
    attr_accessor :value, :previous_version

    def self.build_from_publishing_api(content_id, locale)
      link_set = LinkSet.find(content_id, locale)

      new(
        value: link_set.links["parent"],
        previous_version: link_set.version,
      )
    end
  end
end
