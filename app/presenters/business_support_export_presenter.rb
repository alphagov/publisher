require 'csv'

class BusinessSupportExportPresenter
  def initialize(schemes, facets)
    @schemes = schemes
    @facets = facets
  end

  def area_names(scheme)
    Area.areas_for_edition(scheme).map(&:name).join(", ")
  end

  def facet_names(facet_values)
    [].tap do |ary|
      facet_values.each do |slug|
        ary << @facets[slug]
      end
    end.join(", ")
  end

  def to_csv
    CSV.generate do |csv|
      csv << [
        "title",
        "web URL", "organiser", "short description", "body",
        "eligibility", "evaluation", "additional information", "contact details",
        "max employees", "min value", "max value",
        "continuation link", "will continue on", "start date", "end date",
        "areas", "business sizes", "locations", "purposes", "sectors",
        "stages","support types"
      ]
      @schemes.each do |scheme|
        csv << [
          scheme.title,
          "#{Plek.current.website_root}/#{scheme.slug}", scheme.organiser, scheme.short_description, scheme.body,
          scheme.eligibility, scheme.evaluation, scheme.additional_information, scheme.contact_details,
          scheme.max_employees, scheme.min_value, scheme.max_value,
          scheme.continuation_link, scheme.will_continue_on, scheme.start_date, scheme.end_date,
          area_names(scheme), facet_names(scheme.business_sizes), facet_names(scheme.locations),
          facet_names(scheme.purposes), facet_names(scheme.sectors),
          facet_names(scheme.stages), facet_names(scheme.support_types)
        ]
      end
    end
  end
end
