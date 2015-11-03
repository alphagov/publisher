class BusinessSupportExportPresenter < CSVPresenter
  private

  def build_csv(csv)
    csv << [
      "title",
      "web URL", "organiser", "short description", "body",
      "eligibility", "evaluation", "additional information", "contact details",
      "max employees", "min value", "max value",
      "continuation link", "will continue on", "start date", "end date",
      "areas", "business sizes", "locations", "purposes", "sectors",
      "stages","support types"
    ]
    scope.each do |scheme|
      csv << [
        scheme.title, "#{Plek.current.website_root}/#{scheme.slug}",
        scheme.organiser, scheme.short_description, scheme.body,
        scheme.eligibility, scheme.evaluation, scheme.additional_information,
        scheme.contact_details, scheme.max_employees, scheme.min_value,
        scheme.max_value, scheme.continuation_link, scheme.will_continue_on,
        scheme.start_date, scheme.end_date, area_names(scheme),
        facet_names("BusinessSize", scheme.business_sizes),
        facet_names("Location", scheme.locations),
        facet_names("Purpose", scheme.purposes),
        facet_names("Sector", scheme.sectors),
        facet_names("Stage", scheme.stages),
        facet_names("SupportType", scheme.support_types)
      ]
    end
  end

  def facets
    facet_mappings = {}

    facet_classes = [
      BusinessSupport::BusinessSize,
      BusinessSupport::Location,
      BusinessSupport::Purpose,
      BusinessSupport::Sector,
      BusinessSupport::Stage,
      BusinessSupport::SupportType
    ]

    facet_classes.each do |facet_class|
      facet_class_key = facet_class.to_s.demodulize
      facet_mappings[facet_class_key] = {} unless facet_mappings.has_key?(facet_class_key)
      facet_class.all.each do |facet|
        facet_mappings[facet_class_key][facet.slug] = facet.name
      end
    end

    facet_mappings
  end

  def area_names(scheme)
    Area.areas_for_edition(scheme).map(&:name).join(", ")
  end

  def facet_names(facet_type, facet_values)
    [].tap do |ary|
      facet_values.each do |slug|
        ary << facets[facet_type][slug]
      end
    end.join(", ")
  end
end
