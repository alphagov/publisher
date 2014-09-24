module EditionsHelper
  # edition transitions are done using fields inlined in the edition form.
  # we need to render activity forms to allow edition transitions on views
  # where the edition form is not present i.e. editions diff view.
  def activity_forms_required?
    params[:action] == 'diff'
  end

  def resource_form(&form_definition)
    semantic_bootstrap_nested_form_for @resource, :as => :edition, :url => edition_path(@resource),
      :html => { :id => 'edition-form' }, &form_definition
  end
end
