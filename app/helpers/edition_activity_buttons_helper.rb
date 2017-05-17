module EditionActivityButtonsHelper
  def build_review_button(edition, activity, title)
    check_method = "can_#{activity}?".to_sym
    enabled = edition.send(check_method)

    link_to title, "##{activity}_form", data: { toggle: 'modal' },
      class: "btn btn-info #{'disabled' if !enabled} add-top-margin"
  end

  def review_buttons(edition)
    buttons = []
    buttons << build_review_button(edition, "request_amendments", "Needs more work")
    buttons << build_review_button(edition, "approve_review", "OK for publication")
    buttons.join("\n").html_safe
  end

  def fact_check_buttons(edition)
    [
      ["Needs major changes", "request_amendments"],
      ["Minor or no changes required", "approve_fact_check"]
    ].map { |title, activity|
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

      link_to title, "##{activity}_form", data: { toggle: 'modal' },
        class: "btn btn-large btn-#{button_color} #{'disabled' if disabled}"
    }.join("\n").html_safe
  end

  def scheduled_publishing_buttons(edition)
    buttons = []
    buttons << %w(Schedule schedule_for_publishing warning) if edition.can_schedule_for_publishing?
    buttons << ["Cancel scheduled publishing", "cancel_scheduled_publishing", 'danger'] if edition.can_cancel_scheduled_publishing?
    buttons
  end

  def publish_button(edition)
    button_text = edition.scheduled_for_publishing? ? "Publish now" : "Publish"
    [button_text, "publish"]
  end

  def preview_button(edition)
    if edition.published?
      link_to('View this on the GOV.UK website', "#{Plek.new.website_root}/#{edition.slug}", class: 'btn btn-primary btn-large')
    elsif edition.archived?
      link_to('Preview', '#', class: 'btn btn-primary btn-large disabled')
    else
      link_to('Preview', preview_edition_path(edition), class: 'btn btn-primary btn-large')
    end
  end

  def skip_review?
    current_user.permissions.include?("skip_review")
  end
end
