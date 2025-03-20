module EditionActivityButtonsHelper
  def build_review_button(edition, activity, title)
    check_method = "can_#{activity}?".to_sym
    enabled = edition.send(check_method)

    link_to title,
            "##{activity}_form",
            data: { toggle: "modal" },
            class: "btn btn-info #{'disabled' unless enabled} add-top-margin"
  end

  def review_buttons(edition)
    buttons = []
    if current_user.has_editor_permissions?(edition)
      buttons << build_review_button(edition, "request_amendments", "Needs more work")
      buttons << build_review_button(edition, "approve_review", "No changes needed")
    end
    buttons.join("\n").html_safe
  end

  def fact_check_buttons(edition)
    [
      ["Needs more work", "request_amendments"],
      ["No more work needed", "approve_fact_check"],
    ].map { |title, activity|
      build_review_button(edition, activity, title)
    }.join("\n").html_safe
  end

  def resend_fact_check_buttons(edition)
    build_review_button(edition, "resend_fact_check", "Resend fact check email")
  end

  def progress_buttons(edition, options = {})
    buttons = [
      ["Fact check", "send_fact_check"],
    ]

    if current_user.has_editor_permissions?(edition)
      buttons.push(
        ["2nd pair of eyes", "request_review"],
        *scheduled_publishing_buttons(edition),
        publish_button(edition),
      )
    end

    buttons = buttons.map do |title, activity, button_color = "primary"|
      disabled = !edition.send("can_#{activity}?")
      next if disabled && options.fetch(:skip_disabled_buttons, false)

      link_to title,
              "##{activity}_form",
              data: { toggle: "modal" },
              class: "btn btn-large btn-#{button_color} #{'disabled' if disabled}"
    end

    buttons.join("\n").html_safe
  end

  def scheduled_publishing_buttons(edition)
    buttons = []
    buttons << %w[Schedule schedule_for_publishing warning] if edition.can_schedule_for_publishing?
    buttons << ["Cancel scheduled publishing", "cancel_scheduled_publishing", "danger"] if edition.can_cancel_scheduled_publishing?
    buttons
  end

  def publish_button(edition)
    button_text = edition.scheduled_for_publishing? ? "Publish now" : "Publish"
    [button_text, "publish"]
  end

  def preview_button(edition)
    if edition.published?
      link_to("View this on the GOV.UK website", "#{Plek.website_root}/#{edition.slug}", class: "btn btn-primary btn-large")
    elsif edition.archived?
      link_to("Preview", "#", class: "btn btn-primary btn-large disabled")
    else
      link_to("Preview", preview_edition_path(edition), class: "btn btn-primary btn-large")
    end
  end
end
