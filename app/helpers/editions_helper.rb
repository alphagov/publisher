module EditionsHelper
  # edition transitions are done using fields inlined in the edition form.
  # we need to render activity forms to allow edition transitions on views
  # where the edition form is not present i.e. editions diff view.
  def activity_forms_required?
    params[:action] == 'diff'
  end

  def resource_form(&form_definition)
    html_options = { :id => 'edition-form' }
    unless @resource.locked_for_edits? or @resource.archived?
      if @resource.is_a?(Parted)
        html_options['data-module'] = 'ajax-save-with-parts'
      elsif @resource.format != 'SimpleSmartAnswer'
        html_options['data-module'] = 'ajax-save'
      end
    end

    semantic_bootstrap_nested_form_for @resource, :as => :edition, :url => edition_path(@resource),
      :html => html_options, &form_definition
  end

  def format_conversion_select_options(edition)
    possible_target_formats = Edition.convertible_formats - [edition.artefact.kind]
    possible_target_formats.map{|format_name| [format_name.humanize, format_name]}
  end

  def format_filter_selection_options
    [%w(All edition)] +
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].map do |format_name|
        displayed_format_name = format_name.humanize
        displayed_format_name += " (Retired)" if Artefact::RETIRED_FORMATS.include?(format_name)
        [displayed_format_name, format_name]
      end
  end
end
