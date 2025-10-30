class RecentContentWorkflowPresenter < CSVPresenter
  def initialize(scope = Edition.all)
    super(scope)
    self.column_headings = %i[
      content_title
      content_slug
      content_url
      current_status
      stage
      format
      current_assignee
      created_at
      version_number
      date_created
      time_created
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
          action.created_at.to_fs(:db),
          item.version_number,
          action.created_at.to_date.to_s,
          action.created_at.to_fs(:time),
        ]
      end
    end
  end
end
