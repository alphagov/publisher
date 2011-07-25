module Admin::GuidesHelper
  def preview_edition_path(edition)
    preview_edition_prefix_path(edition.version_number) + "/#{edition.container.slug}"
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
    path = case edition.container.class
    when Answer
      progress_admin_answer_path(guide, :activity => activity, :edition_id => edition)
    when Guide
      progress_admin_guide_path(guide, :activity => activity, :edition_id => edition)
    when Transaction
      progress_admin_transaction_path(guide, :activity => activity, :edition_id => edition)
    end
    
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
    case publication.class
    when Guide
      admin_guide_editions_path(publication)
    when Transaction
      admin_transaction_editions_path(publication)
    when Answer
      admin_answer_editions_path(publication)
    end
  end
  
end
