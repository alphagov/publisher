class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    @user_filter = params[:user_filter] || session[:user_filter]
    @list = params[:list].blank? ? 'lined_up' : params[:list]

    if @user_filter.blank?
      @user_filter = current_user.uid
      user = current_user
    elsif %w[ all nobody ].include?(@user_filter)
      user = @user_filter.to_sym
    else
      user = User.where(uid: @user_filter).first
    end

    session[:user_filter] = @user_filter

    @presenter = AdminRootPresenter.new(user)

    if params[:title_filter]
      @presenter.filter_by_title_substring(params[:title_filter])
    end
  end
end
