module PublicationsHelper
  def status_class_for(publication)
    "factchecked" if publication.fact_checked?
  end

  def timestamp(time)
    return if time.nil?

    %(<time datetime="#{time.strftime('%Y-%m-%dT%H:%M:%SZ')}">#{time.strftime('%d/%m/%Y %H:%M')}</time>).html_safe
  end

  def content_tagger_url(edition)
    content_id = edition.artefact.content_id
    Plek.external_url_for("content-tagger") + "/content/#{content_id}"
  end

  def enabled_users_select_options
    options = User.enabled.order([:name]).collect { |u| [u.name, u.id] }
    options.unshift(["", ""])
  end
end
