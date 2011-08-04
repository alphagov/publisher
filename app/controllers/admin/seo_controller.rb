class Admin::SeoController < ActionController::Base

  def google_insight
    @search_term = params[:search_term]
    render 'google_insight'
  end

end