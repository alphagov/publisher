require 'external_services'

module Admin::GuidesHelper

  def path_for_edition(edition)
    send("admin_#{edition.container.class.to_s.underscore}_edition_path", edition.container, edition)
  end

  def edition_can_be_deleted?(edition)
    edition.container.editions.size > 1 and ! edition.is_published? 
  end

  def produce_fact_check_request_text
    @edition = @latest_edition
    render :partial => '/noisy_workflow/request_fact_check'
  end

  def safe_to_preview?(publication)
    return true unless publication.is_a?(Guide)
    return (publication.latest_edition.parts.any? and publication.latest_edition.parts.first.slug.present?)
  end

  def publication_front_end_path(publication)
    "#{ExternalServices.front_end_host}/#{publication.slug}"
  end

  def preview_edition_path(edition)
    publication_front_end_path(edition.container)+"?edition=#{edition.version_number}"
  end

  def progress_forms(edition)
    [
      ["Fact check",       "request_fact_check", "Enter email addresses"],
      ["2nd pair of eyes", "request_review"],
      ["Publish",          "publish"]
    ].map { |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def progress_form(edition, title, activity, placeholder=nil)
    container    = edition.container.class.to_s.underscore
    path_method  = "progress_admin_#{container}_edition_path".to_sym
    path         = send(path_method, edition, "#{container}_id".to_sym => edition.container)
    check_method = "can_#{activity}?".to_sym

    render(
      :partial => 'admin/shared/activity_form',
      :locals => {
        :url => path, :title => title, :id => activity+"_form",
        :disabled => !edition.send(check_method), :activity => activity
      }
    )
  end

  def review_buttons(guide,edition)
    [
      ["Needs more work",    "review"],
      ["OK for publication", "okay"]
    ].map{ |title,activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled" 
      "<form id=\"#{activity}_toggle\" class=\"button_to review_button\">
      <input type=\"submit\" value=\"#{title}\"  #{disabled}>
      </form>"
    }.join("\n").html_safe
  end

  def review_forms(guide,edition)
    [
      ["Needs more work",    "review"],
      ["OK for publication", "okay"]
    ].map{ |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def progress_buttons(edition)
    guide = edition.container
    [
      ["Fact check",       "request_fact_check"],
      ["2nd pair of eyes", "request_review"],
      ["Publish",          "publish"]
    ].map{ |title,activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled"
      "<form id=\"#{activity}_toggle\" class=\"button_to progress_button\">
      <input type=\"submit\" value=\"#{title}\"  #{disabled}>
      </form>"
    }.join("\n").html_safe
  end

  def preview_button(edition)
    form_tag(preview_edition_path(edition), :method => :get, :class => 'preview button_to also_save_edition') do
      hidden_field_tag('edition', edition.version_number) + submit_tag('Preview')
    end
  end

  def friendly_date(date)
    if Time.now - date < 2.days
      time_ago_in_words(date) + " ago."
    else
      date.strftime("%d/%m/%Y %R")
    end
  end

  def admin_editions_path(publication)
    send("admin_#{publication.class.to_s.underscore}_editions_path", publication)
  end

  def start_work_path(edition)
    publication = edition.container
    send("start_work_admin_#{edition.class.to_s.underscore}_path", publication, edition)
  end
end
