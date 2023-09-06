class AllEditionChurnPresenter < CSVPresenter
  def initialize(scope = Edition.all)
    super(scope)
    self.column_headings = %i[
      id
      panopticon_id
      name
      slug
      state
      editioned_on
      version_number
      date_created
      time_created
    ]
  end

private

  def get_value(header, edition)
    case header
    when :name
      edition.title
    when :editioned_on
      edition.created_at.iso8601
    when :date_created
      edition.created_at.to_date.to_s
    when :time_created
      edition.created_at.to_fs(:time)
    else
      super
    end
  end
end
