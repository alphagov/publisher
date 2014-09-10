module EditionsHelper
  def format_content_diff( body )
    ContentDiffFormatter.new(body).to_html
  end

  # edition transitions are done using fields inlined in the edition form.
  # we need to render activity forms to allow edition transitions on views
  # where the edition form is not present i.e. editions diff view.
  def activity_forms_required?
    params[:action] == 'diff'
  end
end
