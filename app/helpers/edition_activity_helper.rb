module EditionActivityHelper
  def edition_activities_fields(f, edition)
    activities_fields = Edition::ACTIONS.map do |activity, title|
      content_tag(:div, modal_attributes.merge(id: "#{activity}_form")) do
        edition_activity_fields(edition, title, activity, f, inline: true)
      end
    end

    activities_fields.join("\n").html_safe
  end

  def edition_activities_forms(edition, activities)
    activities_forms = activities.map do |activity, title|
      semantic_form_for(:edition, url: progress_edition_path(edition),
        html: modal_attributes.merge(id: "#{activity}_form")) do |f|
        edition_activity_fields(edition, title, activity, f, inline: false)
      end
    end

    activities_forms.join("\n").html_safe
  end

  def edition_activity_fields(edition, title, activity, form_builder, options)
    render(
      :partial => 'shared/edition_activity_fields',
      :locals => {
        :form_builder => form_builder, :title => title, :activity => activity,
        :inline => options[:inline], :disabled => !edition.send("can_#{activity}?".to_sym)
      }
    )
  end

  def review_forms(edition)
    edition_activities_forms(edition, Edition::REVIEW_ACTIONS)
  end

  def fact_check_forms(edition)
    edition_activities_forms(edition, Edition::FACT_CHECK_ACTIONS)
  end

  def modal_attributes
    { :role => 'dialog', :class => 'modal', :tabindex => -1, 'aria-hidden' => true }
  end

end
