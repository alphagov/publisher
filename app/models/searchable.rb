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
      "format" => format.underscore.downcase,
      "description" => (published? && overview) || "",
      "indexable_content" => indexable_content,
    }.merge(split_section(section))
  end
  
  def split_section(section)
    section, subsection = (section || "").split(':', 2).map { |s| s.parameterize }
    {
      "section" => section,
      "subsection" => subsection
    }
  end
  
  module ClassMethods
    def search_index_all
      published.map(&:search_index)
    end
  end
end