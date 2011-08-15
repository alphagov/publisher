module Admin::GuidesHelper
  def safe_to_preview?(publication)
    return true unless publication.is_a?(Guide)
    return (publication.latest_edition.parts.any? and publication.latest_edition.parts.first.slug.present?)
  end

  def publication_front_end_path(publication)
    if publication.is_a?(Place)
      "/places/#{publication.slug}"
    else
      "/#{publication.slug}"
    end
  end

  def preview_edition_path(edition)
    if edition.is_a?(PlaceEdition)
      places_preview_edition_prefix_path(edition.version_number) + "/#{edition.container.slug}"
    else
      preview_edition_prefix_path(edition.version_number) + "/#{edition.container.slug}"
    end
  rescue => e
    Rails.logger.warn e.inspect
    return '#'
  end

  def activity_form(name, id, url, html_options = {})
    html_options = html_options.stringify_keys
    convert_boolean_attributes!(html_options, ["disabled"] )

    request_token_tag = ''
    if protect_against_forgery?
      request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
    end
    
    comment_field =  tag(:input,:name=>'comment',:placeholder=>"Please enter a comment")
    cancel_button =  tag(:input,:type=>"submit",
                         :class=>"button_to",
                         :style=>"width:auto",
                         :value=>"Cancel",
                         :onclick=>"$('.workflow_buttons').show();$('##{id}').hide();return false;")
    
    html_options = convert_options_to_data_attributes({}, html_options)
    html_options.merge!("type" => "submit", "value" => name,:style=>"width:auto")

    ("<form id=\"#{id}\" method=\"post\" action=\"#{html_escape(url)}\"
       class=\"button_to also_save_edition\" style=\"display:none\">" + comment_field  + 
      cancel_button + tag("input", html_options)  + request_token_tag + "</form>").html_safe
  end

  def progress_form(opts)
    title,guide,edition,activity = opts[:title],opts[:guide],opts[:edition],opts[:activity]
    check_method = "can_#{activity}?".to_sym
    path = send("progress_admin_#{guide.class.to_s.underscore}_path", guide, :activity => activity, :edition_id => edition)
    activity_form title, activity+"_form", path, :disabled => !edition.send(check_method)
  end
  
  def review_buttons(guide,edition)
    [
        ["Needs more work","review"],
        ["OK for publication","okay"]
    ].map{ |title,activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled" 
     "<form id=\"#{activity}_toggle\" class=\"button_to\" onsubmit=\"$('##{activity}_form').toggle();$('.workflow_buttons').hide();return false;\">
     <input type=\"submit\" value=\"#{title}\"  #{disabled}>
     </form>"
   }.join("\n").html_safe
  end
  
  def review_forms(guide,edition)
     [
        ["Needs more work","review"],
        ["OK for publication","okay"]
      ].map{ |title,activity|
        progress_form(:title=>title,:guide=>guide,:activity=>activity,:edition=>edition)
      }.join("\n").html_safe
  end
  
  def progress_buttons(guide,edition)
    [
        ["2nd pair of eyes","request_review"],
        ["Publish","publish"]
    ].map{ |title,activity|
      check_method = "can_#{activity}?".to_sym
      disabled = edition.send(check_method) ? "" : "disabled"
     "<form id=\"#{activity}_toggle\" class=\"button_to\" onsubmit=\"$('##{activity}_form').toggle();$('.workflow_buttons').hide();return false;\">
     <input type=\"submit\" value=\"#{title}\"  #{disabled}>
     </form>"
   }.join("\n").html_safe
  end
  
  def progress_forms(guide,edition)
    [
      ["2nd pair of eyes","request_review"],
      ["Publish","publish"]
    ].map{ |title,activity|
      progress_form(:title=>title,:guide=>guide,:activity=>activity,:edition=>edition)
    }.join("\n").html_safe
  end
  
  def preview_button(edition)
    form_tag(preview_edition_path(edition), :method => :get, :class => 'preview button_to also_save_edition') do
      submit_tag 'Preview'
    end
  end
  
  def friendly_date(date)
#    .strftime("%d/%m/%Y %R")
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
