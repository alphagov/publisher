class RootController < ApplicationController
  respond_to :html, :json

  include ColumnSortable

  ITEMS_PER_PAGE = 20

  STATE_NAME_LISTS = {"draft" => "drafts", "fact_check" => "out_for_fact_check"}

  def index
    user_filter           = params[:user_filter] || session[:user_filter]
    session[:user_filter] = user_filter

    if params[:with]
      raise "Cannot specify both 'with' and 'string_filter' parameters." if params[:string_filter]
      raise "Cannot specify both 'with' and 'page' parameters." if params[:page]

      @presenter, @user_filter, @list = build_with_focus(user_filter)
    else
      @list = params[:list].blank? ? 'lined_up' : params[:list]
      @presenter, @user_filter = build_without_focus(user_filter, params[:page])
    end

    # Looking at another class, but the whole approach taken by this method and its
    # associated presenter needs revisiting.
    unless @presenter.acceptable_list?(@list)
      render text: 'Not Found', status: 404 and return
    end

    if params[:string_filter].present?
      clean_string_filter = params[:string_filter]
                              .strip
                              .gsub(/\s+/, ' ')
      @presenter.filter_by_substring(clean_string_filter)
    end
  end

private

  def list_parameter_from_state(state)
    STATE_NAME_LISTS[state] || state
  end

  def build_without_focus(user_filter, current_page = nil)
    user_filter, user = process_user_filter(user_filter)
    editions = Edition.order_by([sort_column, sort_direction])
    editions = editions.page(current_page).per(ITEMS_PER_PAGE)
    return PrimaryListingPresenter.new(editions, user), user_filter
  end

  def edition_of_interest
    Edition.find(params[:with])
  rescue Mongoid::Errors::DocumentNotFound, BSON::InvalidObjectId
    raise ActionController::RoutingError.new('Not Found')
  end

  def build_with_focus(user_filter)
    edition = edition_of_interest

    if edition.assigned_to.nil? or edition.assigned_to.uid != user_filter
      user_filter = "all"
    end

    user_filter, user = process_user_filter(user_filter)

    editions = Edition.order_by([sort_column, sort_direction])

    item_index = editions.send(edition.state).to_a.index { |e| e.id == edition.id }
    current_page = (item_index / ITEMS_PER_PAGE) + 1
    editions = editions.page(current_page).per(ITEMS_PER_PAGE)

    list = list_parameter_from_state(edition.state)
    return PrimaryListingPresenter.new(editions, user), user_filter, list
  end

  def process_user_filter(user_filter = nil)
    if user_filter.blank?
      user_filter = current_user.uid
      user = current_user
    elsif %w[ all nobody ].include?(user_filter)
      user = user_filter.to_sym
    else
      user = User.where(uid: user_filter).first
    end

    return user_filter, user
  end
end
