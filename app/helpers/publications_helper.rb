module PublicationsHelper

  def status_class_for(publication)                  
    return 'factchecked' if publication.latest_edition.fact_checked?
  end

end
