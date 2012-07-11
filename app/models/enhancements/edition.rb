require "edition"

class Edition
  include Admin::BaseHelper
  include Searchable

  alias_method :was_published_without_indexing, :was_published
  def was_published
    was_published_without_indexing
    update_in_search_index
  end

  def fact_check_skipped?
    actions.any? and actions.last.request_type == 'skip_fact_check'
  end
end
