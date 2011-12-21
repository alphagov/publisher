module Searchable
  extend ActiveSupport::Concern
  
  included do
    after_destroy :remove_from_search_index
  end

  def update_in_search_index
    Rummageable.index(search_index)
  end

  def remove_from_search_index
    Rummageable.delete "/#{slug}"
  end
  
  def indexable_content
    published? ? alternative_title : ""
  end

  def search_index
    {
      "title" => title,
      "link" => "/#{slug}",
      "section" => section ? section.parameterize : nil,
      "format" => format.underscore.downcase,
      "description" => (published? && overview) || "",
      "indexable_content" => indexable_content,
    }
  end
  
  def self.search_index_all
    all.map(&:search_index)
  end
end