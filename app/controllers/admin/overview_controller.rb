class Admin::OverviewController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  def index
    @overviews = {
      :format =>  Publication.count_by(Publication::FORMAT),
      :section => Publication.count_by(Publication::SECTION),
      :department => Publication.count_by(Publication::DEPARTMENT)
    }
  end
end
