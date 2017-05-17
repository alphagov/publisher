class PrimaryListingPresenter
  AVAILABLE_LISTS = [
    :draft,
    :amends_needed,
    :in_review,
    :fact_check,
    :fact_check_received,
    :ready,
    :scheduled_for_publishing,
    :published,
    :archived,
  ]

  # There's some discrepancy between the scope names and partial
  # names so we need a mapping (scope_name => partial_name) to
  # help identify acceptable names
  LIST_TRANSLATIONS = {
    draft: :drafts,
    fact_check: :out_for_fact_check,
  }

  def initialize(editions, user)
    @scope = case user
             when :all
               editions
             when :nobody
               editions.assigned_to(nil)
             else
               editions.assigned_to(user)
             end
  end

  attr_accessor :scope
  private :scope

  def acceptable_list?(list)
    available_partials = AVAILABLE_LISTS.map do |scope|
      LIST_TRANSLATIONS[scope] ? LIST_TRANSLATIONS[scope] : scope
    end

    available_partials.include?(list.to_sym)
  end

  def all
    @scope
  end

  AVAILABLE_LISTS.each do |state|
    define_method state do
      scope.send(state.to_s)
    end
  end

  def filter_by_substring(s)
    @scope = @scope.internal_search(s)
  end

  alias_method :drafts, :draft
  alias_method :out_for_fact_check, :fact_check
end
