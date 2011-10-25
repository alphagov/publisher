class Admin::OverviewController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  def index
    @overviews = {
      'Format' =>  Publication.count_by(Publication::FORMAT),
      'Section' => Publication.count_by(Publication::SECTION),
      'Writing Department' => Publication.count_by(Publication::DEPARTMENT)
    }
  end
end
