class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    @filter = params[:filter] || session[:filter]

    if @filter.blank?
      @filter = current_user.uid
      user = current_user
    elsif %w[ all nobody ].include?(@filter)
      user = @filter.to_sym
    else
      user = User.where(uid: @filter).first
    end

    session[:filter] = @filter

    @presenter = AdminRootPresenter.new(user)

    @lined_up             = @presenter.lined_up
    @draft                = @presenter.draft
    @amends_needed        = @presenter.amends_needed
    @in_review            = @presenter.in_review
    @fact_check           = @presenter.fact_check
    @fact_check_received  = @presenter.fact_check_received
    @ready                = @presenter.ready
    @published            = @presenter.published
    @archived             = @presenter.archived

    if params[:list]
      headers['X-Slimmer-Skip'] = '1'
      render partial: params[:list], layout: false and return
    end
  end
end
