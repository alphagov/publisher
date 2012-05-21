class Admin::RootController < Admin::BaseController
  respond_to :html, :json
  helper_method :sort_column, :sort_direction

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
    
    whole_editions = WholeEdition.order_by([sort_column, sort_direction])
        .page(params[:page])
        .per(20)
    @presenter = AdminRootPresenter.new(whole_editions, user)

    if ! params[:title_filter].blank?
      @presenter.filter_by_title_substring(params[:title_filter])
    end
  end

  private
  
    def sort_column
      WholeEdition.fields.keys.include?(params[:sort]) ? params[:sort] : "updated_at"
    end
    
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end
