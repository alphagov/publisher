module EditionActivityButtonsHelper

  def build_review_button(edition, activity, title)
    check_method = "can_#{activity}?".to_sym
    enabled = edition.send(check_method)

    link_to title, "##{activity}_form", data: { toggle: 'modal'},
      class: "btn btn-info #{"disabled" if !enabled} add-top-margin"
  end

  def review_buttons(edition)
    [
      ["Needs more work", "request_amendments"],
      ["OK for publication", "approve_review"]
    ].map{ |title, activity|
      build_review_button(edition, activity, title)
    }.join("\n").html_safe
  end

  def fact_check_buttons(edition)
    [
      ["Needs major changes", "request_amendments"],
      ["Minor or no changes required", "approve_fact_check"]
    ].map{ |title, activity|
      build_review_button(edition, activity, title)
    }.join("\n").html_safe
  end

  def progress_buttons(edition, options = {})
    [
      ["Fact check", "send_fact_check"],
      ["2nd pair of eyes", "request_review"],
      *scheduled_publishing_buttons(edition),
      publish_button(edition),
    ].map { |title, activity, button_color = 'primary'|
      disabled = !edition.send("can_#{activity}?")
      next if disabled && options.fetch(:skip_disabled_buttons, false)

      link_to title, "##{activity}_form", data: { toggle: 'modal'},
        class: "btn btn-large btn-#{button_color} #{"disabled" if disabled}"
    }.join("\n").html_safe
  end

  def scheduled_publishing_buttons(edition)
    buttons = []
    buttons << ["Schedule", "schedule_for_publishing", 'warning'] if edition.can_schedule_for_publishing?
    buttons << ["Cancel scheduled publishing", "cancel_scheduled_publishing", 'danger'] if edition.can_cancel_scheduled_publishing?
    buttons
  end

  def publish_button(edition)
    button_text = edition.scheduled_for_publishing? ? "Publish now" : "Publish"
    [button_text, "publish"]
  end

  def preview_button(edition)
    link_to('Preview', preview_edition_path(edition), class: 'btn btn-primary btn-large')
  end

end
