require 'csv'

class BusinessSupportExportPresenter
  def initialize(schemes)
    @schemes = schemes
  end

  def to_csv
    CSV.generate do |csv|
      csv << [
        "id","title",
        "web URL", "organiser", "short description", "body",
        "eligibility", "evaluation", "additional information", "contact details",
        "max employees", "min value", "max value",
        "continuation link", "will continue on",
      ]
      @schemes.each do |scheme|
        csv << [
          scheme.business_support_identifier, scheme.title,
          "#{Plek.current.website_root}/#{scheme.slug}", scheme.organiser, scheme.short_description, scheme.body,
          scheme.eligibility, scheme.evaluation, scheme.additional_information, scheme.contact_details,
          scheme.max_employees, scheme.min_value, scheme.max_value,
          scheme.continuation_link, scheme.will_continue_on,
        ]
      end
    end
  end
end
