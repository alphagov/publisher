module Admin::ProgressFormsHelper
  def progress_forms(edition)
    [
      ["Fact check",       "send_fact_check", "Enter email addresses"],
      ["2nd pair of eyes", "request_review"],
      ["Publish",          "publish"]
    ].map { |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def progress_form(edition, title, activity, placeholder=nil)
    path_method  = "progress_admin_edition_path".to_sym
    path         = send(path_method, edition)
    check_method = "can_#{activity}?".to_sym

    render(
      :partial => 'admin/shared/activity_form',
      :locals => {
        :url => path, :title => title, :id => activity+"_form",
        :disabled => !edition.send(check_method), :activity => activity
      }
    )
  end

  def review_buttons(edition)
    [
      ["Needs more work",    "request_amendments"],
      ["OK for publication", "approve_review"]
    ].map{ |title, activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled"
      %{<button data-toggle="modal" href="##{activity}_form" class="btn btn-primary" value="#{title}" type="submit" #{disabled}>#{title}</button>}
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
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled"
      %{<button data-toggle="modal" href="##{activity}_form" class="btn btn-primary" value="#{title}" type="submit" #{disabled}>#{title}</button>}
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
      ["Fact check",       "send_fact_check"],
      ["2nd pair of eyes", "request_review"],
      ["Publish",          "publish"]
    ].map { |title, activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled"
      %{<button data-toggle="modal" href="##{activity}_form" class="btn btn-primary btn-large" value="#{title}" type="submit" #{disabled}>#{title}</button>}
    }.join("\n").html_safe
  end

  def preview_button(edition)
    form_tag(preview_edition_path(edition), :method => :get) do
      hidden_field_tag('cache', Time.now().to_i) +
      hidden_field_tag('edition', edition.version_number) +
      submit_tag('Preview', class: 'btn btn-primary btn-large')
    end
  end
end