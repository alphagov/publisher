class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    presenter = AdminRootPresenter.new(:all)

    @drafts           = presenter.in_draft
    @published        = presenter.published
    @archive          = presenter.archive
    @review_requested = presenter.review_requested
    @fact_checking    = presenter.fact_checking
    @lined_up         = presenter.lined_up
  end
end
