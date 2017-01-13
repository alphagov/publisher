module PublicationsHelper

  def status_class_for(publication)
    return 'factchecked' if publication.fact_checked?
  end

  def timestamp(time)
    return if time.nil?
    %{<time datetime="#{ time.strftime("%Y-%m-%dT%H:%M:%SZ") }">#{ time.strftime("%d/%m/%Y %H:%M") }</time>}.html_safe
  end

  def panopticon_url(edition)
    id = edition.panopticon_id || edition.slug
    Plek.current.find("panopticon") + "/artefacts/#{id}"
  end

  def panopticon_withdraw_url(edition)
    panopticon_url(edition) + '/withdraw'
  end

  def panopticon_edit_url(edition)
    panopticon_url(edition) + '/edit'
  end

  def content_tagger_url(edition)
    content_id = edition.artefact.content_id
    Plek.current.find("content-tagger") + "/content/#{content_id}"
  end

  def enabled_users_select_options(empty_value=true)
    options = User.enabled.order_by([[:name, :asc]]).collect{ |u| [u.name, u.id] }
    options.unshift(["",""]) if empty_value
    options
  end
end
