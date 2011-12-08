class Admin::OverviewController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  def index
    @overviews = {
      'Format' =>  OverviewDashboard.where(:dashboard_type => "Format"),
      'Section' => OverviewDashboard.where(:dashboard_type => "Section").order_by([['result_group','ASC']]),
      'Writing Department' => OverviewDashboard.where(:dashboard_type => "Writing Department")
    }
    
    respond_to do |format|
      format.html { # render overview.html.erb 
        }
      format.json {
        render :json => @overviews.to_json
      }
    end
  end
end
