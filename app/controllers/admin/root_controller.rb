class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    @filter = params[:filter] || session[:filter]
    @list = params[:list].blank? ? 'lined_up' : params[:list]

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
  end
end
