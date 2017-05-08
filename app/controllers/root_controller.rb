class RootController < ApplicationController
  respond_to :html, :json

  include ColumnSortable

  ITEMS_PER_PAGE = 20

  STATE_NAME_LISTS = { "draft" => "drafts", "fact_check" => "out_for_fact_check" }

  def index
    user_filter           = params[:user_filter] || session[:user_filter]
    session[:user_filter] = user_filter

    @list = params[:list].blank? ? 'drafts' : params[:list]
    @presenter, @user_filter = build_presenter(user_filter, params[:page])

    # Looking at another class, but the whole approach taken by this method and its
    # associated presenter needs revisiting.
    unless @presenter.acceptable_list?(@list)
      render body: { 'raw' => 'Not Found'}, status: 404
      return
    end

    if params[:string_filter].present?
      clean_string_filter = params[:string_filter]
        .strip
        .gsub(/\s+/, ' ')
      @presenter.filter_by_substring(clean_string_filter)
    end
  end

private

  def format_filter
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].include?(params[:format_filter]) ? params[:format_filter] : 'edition'
  end

  def filtered_editions
    return Edition if format_filter == 'edition'
    Edition.where(_type: format_filter.camelcase + 'Edition')
  end

  def list_parameter_from_state(state)
    STATE_NAME_LISTS[state] || state
  end

  def build_presenter(user_filter, current_page = nil)
    user_filter, user = process_user_filter(user_filter)
    editions = filtered_editions.order_by([sort_column, sort_direction])
    editions = editions.page(current_page).per(ITEMS_PER_PAGE)
    [PrimaryListingPresenter.new(editions, user), user_filter]
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

    [user_filter, user]
  end
end
