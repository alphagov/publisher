class ContentWorkflowPresenter < CSVPresenter
  def initialize(scope = Edition.published)
    super(scope)
    self.column_headings = [
      :content_title,
      :content_slug,
      :content_url,
      :current_status,
      :stage,
      :format,
      :current_assignee,
      :created_at,
    ]
  end

private

  def build_csv(csv)
    csv << column_headings.collect { |ch| ch.to_s.humanize }
    scope.each do |item|
      item.actions.each do |action|
        csv << [
          item.title,
          item.slug,
          "#{Plek.current.website_root}/#{item.slug}",
          item.state,
          action.request_type,
          item.format,
          item.assignee,
          action.created_at.to_s(:db),
        ]
      end
    end
  end
end
