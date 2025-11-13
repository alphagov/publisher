class AllContentWorkflowPresenter < CSVPresenter
  def initialize(scope)
    super(scope)
    self.column_headings = %i[
      content_title
      content_created
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

    # NOTE: With `find_each` Scoped order is ignored, it's forced to be batch order.
    # This means that the randomly generated UUID primary keys are used (ASC) for the order
    @scope.find_each(batch_size: 500) do |edition|
      edition.actions.find_each(batch_size: 500) do |action|
        csv << [
          edition.title,
          edition.created_at.to_fs(:db),
          edition.slug,
          "#{Plek.website_root}/#{edition.slug}",
          edition.state,
          action.request_type,
          edition.format,
          edition.assignee,
          action.created_at.to_fs(:db),
          edition.version_number,
          action.created_at.to_date.to_s,
          action.created_at.to_fs(:time),
        ]
      end
    end
  end
end
