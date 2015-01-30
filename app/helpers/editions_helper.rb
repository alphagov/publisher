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

  def browse_options_for_select(grouped_collections)
    grouped_collections.map do |parent_title, collections|
      collections = collections.map do |collection|
        if collection.draft?
          collection_title = "#{collection.title} (draft)"
        else
          collection_title = collection.title
        end

        ["#{parent_title}: #{collection_title}", collection.slug]
      end

      [parent_title, collections]
    end
  end
end
