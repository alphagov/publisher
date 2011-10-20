module PublicationsHelper

  def status_class_for(publication)
    return 'reviewed' if publication.latest_edition.has_been_reviewed?
    return 'okay' if publication.latest_edition.has_been_okayed?
    return 'factchecked' if publication.latest_edition.has_been_fact_checked?
  end

end
