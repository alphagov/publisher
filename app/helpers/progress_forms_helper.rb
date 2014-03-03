module ProgressFormsHelper
  def progress_forms(edition)
    [
      ["Send to Fact check", "send_fact_check", "Enter email addresses"],
      ["Send to 2nd pair of eyes", "request_review"],
      ["Schedule for Publishing", "schedule_for_publishing"],
      ["Cancel Scheduled Publishing", "cancel_scheduled_publishing"],
      ["Send to Publish", "publish"],
    ].map { |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def progress_form(edition, title, activity, placeholder=nil)
    path_method  = "progress_edition_path".to_sym
    path         = send(path_method, edition)
    check_method = "can_#{activity}?".to_sym

    render(
      :partial => 'shared/activity_form',
      :locals => {
        :url => path, :title => title, :id => activity+"_form",
        :disabled => !edition.send(check_method), :activity => activity
      }
    )
  end

  def build_review_button(edition, activity, title)
    check_method = "can_#{activity}?".to_sym
    disabled = edition.send(check_method) ? "" : "disabled"
    %{<button data-toggle="modal" href="##{activity}_form" class="btn btn-primary" value="#{title}" type="submit" #{disabled}>#{title}</button>}
  end

  def review_buttons(edition)
    [
      ["Needs more work",    "request_amendments"],
      ["OK for publication", "approve_review"]
    ].map{ |title, activity|
      build_review_button(edition, activity, title)
    }.join("\n").html_safe
  end

  def review_forms(edition)
    [
      ["Needs more work",    "request_amendments"],
      ["OK for publication", "approve_review"]
    ].map{ |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def fact_check_buttons(edition)
    [
      ["Needs major changes",    "request_amendments"],
      ["Minor or no changes required", "approve_fact_check"]
    ].map{ |title, activity|
      build_review_button(edition, activity, title)
    }.join("\n").html_safe
  end

  def fact_check_forms(edition)
    [
      ["Needs major changes",    "request_amendments"],
      ["Minor or no changes required", "approve_fact_check"]
    ].map { |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def progress_buttons(edition)
    [
      ["Fact check", "send_fact_check"],
      ["2nd pair of eyes", "request_review"],
      *scheduled_publishing_buttons(edition),
      ["Publish", "publish"],
    ].map { |title, activity, button_color = 'primary'|
      button_options = {
        type: :submit,
        data: { toggle: 'modal'},
        href: "##{activity}_form",
        class: "btn btn-large btn-#{button_color}",
        disabled: ! edition.send("can_#{activity}?"),
        value: title,
      }
      content_tag(:button, button_options) { title }
    }.join("\n").html_safe
  end

  def scheduled_publishing_buttons(edition)
    buttons = []
    buttons << ["Schedule", "schedule_for_publishing", 'warning'] if edition.can_schedule_for_publishing?
    buttons << ["Cancel scheduled publishing", "cancel_scheduled_publishing", 'danger'] if edition.can_cancel_scheduled_publishing?
    buttons
  end

  def preview_button(edition)
    form_tag(preview_edition_path(edition), :method => :get) do
      hidden_field_tag('cache', Time.zone.now().to_i) +
      hidden_field_tag('edition', edition.version_number) +
      submit_tag('Preview', class: 'btn btn-primary btn-large')
    end
  end
end
