class EditionChurnPresenter < CSVPresenter
  def initialize(scope = Edition.all)
    super(scope)
    self.column_headings = [
      :id,
      :panopticon_id,
      :name,
      :slug,
      :state,
      :browse_pages,
      :primary_topic,
      :additional_topics,
      :organisation,
      :need_ids,
      :editioned_on,
      :version_number
    ]
  end

private

  def get_value(header, edition)
    case header
    when :name
      edition.title
    when :browse_pages
      edition.browse_pages.join(",")
    when :additional_topics
      edition.additional_topics.join(",")
    when :organisation
      edition.department
    when :need_ids
      edition.artefact.need_ids.join(',')
    when :editioned_on
      edition.created_at.iso8601
    else
      super
    end
  end
end
