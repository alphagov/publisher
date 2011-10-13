class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    @filter = params[:filter]

    if @filter.blank?
      @filter = current_user.uid
      user = current_user
    elsif %w[ all nobody ].include?(@filter)
      user = @filter.to_sym
    else
      user = User.where(uid: @filter).first
    end

    presenter = AdminRootPresenter.new(user)

    @drafts           = presenter.in_draft
    @published        = presenter.published
    @archive          = presenter.archive
    @review_requested = presenter.review_requested
    @fact_checking    = presenter.fact_checking
    @lined_up         = presenter.lined_up
  end
end
