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

    if params[:list]
      headers['X-Slimmer-Skip'] = '1'
      render partial: params[:list], layout: false and return
    end
  end
end
