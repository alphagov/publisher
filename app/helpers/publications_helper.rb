module PublicationsHelper

  def status_class_for(publication)
    return 'reviewed' if publication.latest_edition.amends_needed?
    return 'okay' if publication.latest_edition.ready?
    return 'factchecked' if publication.latest_edition.fact_check_received?
  end

end
