class AdminRootPresenter
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

  def all
    @scope
  end

  [:lined_up, :draft, :amends_needed, :in_review, :fact_check, :fact_check_received, :ready, :published, :archived].each do |state|
    define_method state do
      scope.send(state.to_s)
    end
  end

  def filter_by_title_substring(s)
    @scope = @scope.where(title: /#{s}/i)
  end

  alias_method :drafts, :draft
  alias_method :out_for_fact_check, :fact_check
end
