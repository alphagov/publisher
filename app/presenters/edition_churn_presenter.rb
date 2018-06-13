class EditionChurnPresenter < CSVPresenter
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
    ]
  end

private

  def get_value(header, edition)
    case header
    when :name
      edition.title
    when :editioned_on
      edition.created_at.iso8601
    else
      super
    end
  end
end
