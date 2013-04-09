class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  include Admin::ColumnSortable

  ITEMS_PER_PAGE = 20

  STATE_NAME_LISTS = {"draft" => "drafts", "fact_check" => "out_for_fact_check"}

  def index
    @user_filter = params[:user_filter] || session[:user_filter]
    @list = params[:list].blank? ? 'lined_up' : params[:list]

    session[:user_filter] = @user_filter

    if params[:with] && params[:title_filter]
      raise "Cannot specify both 'with' and 'title_filter' parameters."
    end
    if params[:with] && params[:page]
      raise "Cannot specify both 'with' and 'page' parameters."
    end

    if params[:with]
      begin
        edition = Edition.find(params[:with])
      rescue Mongoid::Errors::DocumentNotFound, BSON::InvalidObjectId
        raise ActionController::RoutingError.new('Not Found')
      end

      @list = list_parameter_from_state edition.state
      if edition.assigned_to.nil? or edition.assigned_to.uid != @user_filter
        @user_filter = "all"
      end
    end

    if @user_filter.blank?
      @user_filter = current_user.uid
      user = current_user
    elsif %w[ all nobody ].include?(@user_filter)
      user = @user_filter.to_sym
    else
      user = User.where(uid: @user_filter).first
    end

    editions = Edition.order_by([sort_column, sort_direction])

    if params[:with]
      item_index = editions.send(edition.state).to_a.index { |e| e.id == edition.id }
      current_page = (item_index / ITEMS_PER_PAGE) + 1
    else
      current_page = params[:page]
    end

    editions = editions.page(current_page).per(ITEMS_PER_PAGE)
    @presenter = AdminRootPresenter.new(editions, user)

    # Looking at another class, but the whole approach taken by this method and its
    # associated presenter needs revisiting.
    unless @presenter.acceptable_list?(@list)
      render text: 'Not Found', status: 404 and return
    end

    if ! params[:title_filter].blank?
      clean_title_filter = params[:title_filter]
                              .strip
                              .gsub(/\s+/, ' ')
      @presenter.filter_by_title_substring(clean_title_filter)
    end
  end

private

  def list_parameter_from_state(state)
    STATE_NAME_LISTS[state] || state
  end

end
