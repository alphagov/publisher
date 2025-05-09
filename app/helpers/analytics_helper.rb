module AnalyticsHelper
  def track_analytics_data_on_load(title)
    {
      event: "page_view",
      page_view: {
        publishing_app: "publisher",
        user_created_at: current_user&.created_at&.to_date,
        document_type: title,
      },
    }.to_json
  end
end
