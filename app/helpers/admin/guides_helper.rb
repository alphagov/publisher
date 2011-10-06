require 'external_services'

module Admin::GuidesHelper

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
    ].map { |title,activity, placeholder|
      progress_form(:title=>title,:activity=>activity,:edition=>edition,:placeholder=>placeholder)
    }.join("\n").html_safe
  end

  def progress_form(opts)
    title,edition,activity,placeholder = opts[:title],opts[:edition],opts[:activity],opts[:placeholder]
    check_method = "can_#{activity}?".to_sym
    path = send("progress_admin_#{edition.container.class.to_s.underscore}_path", edition.container)

    render(:partial => 'admin/shared/activity_form', :locals => { :url => path, :name => title, :id => activity+"_form", 
      :disabled => !edition.send(check_method), :activity => activity })
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
    ].map{ |title,activity|
      progress_form(:title=>title,:guide=>guide,:activity=>activity,:edition=>edition)
    }.join("\n").html_safe
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
end
