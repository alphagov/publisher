class EditionChurnPresenter < CSVPresenter
  def initialize(scope = Edition.all)
    super(scope)
    self.column_headings = [
      :id,
      :panopticon_id,
      :name,
      :slug,
      :state,
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
    when :need_ids
      edition.artefact.need_ids.join(',')
    when :editioned_on
      edition.created_at.iso8601
    else
      super
    end
  end
end
