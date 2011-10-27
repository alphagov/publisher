class AdminRootPresenter

  def initialize(user)
    @scope = case user
    when :all
      Publication
    when :nobody
      Publication.assigned_to(nil)
    else
      Publication.assigned_to(user)
    end
  end

  attr_accessor :scope
  private :scope

  def in_draft
    scope.in_draft
  end

  def published
    scope.published
  end

  def archive
    scope.archive
  end

  def review_requested
    scope.review_requested
  end

  def fact_checking
    scope.fact_checking
  end

  def lined_up
    scope.lined_up
  end
end
