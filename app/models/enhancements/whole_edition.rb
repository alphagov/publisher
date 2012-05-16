require 'marples/model_action_broadcast'
require 'whole_edition'

class WholeEdition
  include Marples::ModelActionBroadcast
  include Admin::BaseHelper
  include Searchable

  alias_method :was_published_without_indexing, :was_published
  def was_published
    was_published_without_indexing
    update_in_search_index
  end
end
