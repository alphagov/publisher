class ContentWorkflowPresenter < CSVPresenter
  def initialize(scope = Edition.published)
    super(scope)
    self.column_headings = %i[
      content_title
      content_slug
      content_url
      current_status
      stage
      format
      current_assignee
      version_number
      created_at
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
          "#{Plek.website_root}/#{item.slug}",
          item.state,
          action.request_type,
          item.format,
          item.assignee,
          item.version_number,
          action.created_at.to_fs(:db),
        ]
      end
    end
  end
end
