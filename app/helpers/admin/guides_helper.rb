module Admin::GuidesHelper
  def preview_edition_path(edition)
    preview_edition_prefix_path(edition) + "/#{edition.guide.slug}"
  end
end
