module PublicationsHelper

  def status_class_for(publication)
    return 'factchecked' if publication.fact_checked?
  end

  def timestamp(time)
    %{<time datetime="#{ time.strftime("%Y-%m-%dT%H:%M:%SZ") }">#{ time.strftime("%d/%m/%Y %H:%M") }</time>}.html_safe
  end
end
