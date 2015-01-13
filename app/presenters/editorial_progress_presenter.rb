class EditorialProgressPresenter < CSVPresenter
  include PathsHelper

  def initialize(scope = Edition.all)
    super(scope)
    self.column_headings = [
      :title,
      :slug,
      :preview_url,
      :state,
      :format,
      :version_number,
      :assigned_to,
      :sibling_in_progress,
      :panopticon_id
    ]
  end

private

  def get_value(header, edition)
    case header
    when :preview_url
      preview_edition_path(edition)
    else
      super
    end
  end
end
