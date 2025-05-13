module AnalyticsHelper
  def track_analytics_data_on_load(action_name, controller_name)
    {
      event: "page_view",
      page_view: {
        document_type: "#{action_name}-#{controller_name}",
        publishing_app: "publisher",
        user_created_at: current_user&.created_at&.to_date,
      },
    }.to_json
  end
end
