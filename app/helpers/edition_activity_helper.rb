module EditionActivityHelper
  def edition_activities_fields(f, edition)
    activities = [
      ["Send to Fact check", "send_fact_check", "Enter email addresses"],
      ["Send to 2nd pair of eyes", "request_review"],
      ["Schedule for Publishing", "schedule_for_publishing"],
      ["Cancel Scheduled Publishing", "cancel_scheduled_publishing"],
      ["Send to Publish", "publish"],
    ]

    activities_fields = activities.map do |title, activity|
      content_tag(:div, modal_attributes.merge(id: "#{activity}_form")) do
        edition_activity_fields(edition, title, activity, f, inline: true)
      end
    end

    activities_fields.join("\n").html_safe
  end

  def edition_activities_forms(edition, activities)
    activities_forms = activities.map do |title, activity|
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
    activities = [
      ["Request amendments", "request_amendments"],
      ["Approve review", "approve_review"]
    ]

    edition_activities_forms(edition, activities)
  end

  def fact_check_forms(edition)
    activities = [
      ["Request amendments", "request_amendments"],
      ["Approve fact check", "approve_fact_check"]
    ]

    edition_activities_forms(edition, activities)
  end

  def modal_attributes
    { :role => 'dialog', :class => 'modal', :tabindex => -1, 'aria-hidden' => true }
  end

end
