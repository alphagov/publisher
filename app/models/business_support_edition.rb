# encoding: utf-8
require "edition"

class BusinessSupportEdition < Edition
  field :short_description, type: String
  field :body, type: String
  field :min_value, type: Integer
  field :max_value, type: Integer
  field :max_employees, type: Integer
  field :organiser, type: String
  field :eligibility, type: String
  field :evaluation, type: String
  field :additional_information, type: String
  field :continuation_link, type: String
  field :will_continue_on, type: String
  field :contact_details, type: String

  field :priority,        type: Integer, default: 1
  field :business_types,  type: Array, default: []
  field :business_sizes,  type: Array, default: []
  field :locations,       type: Array, default: []
  field :purposes,        type: Array, default: []
  field :sectors,         type: Array, default: []
  field :stages,          type: Array, default: []
  field :support_types,   type: Array, default: []
  field :start_date,      type: Date
  field :end_date,        type: Date
  field :area_gss_codes,  type: Array, default: []

  GOVSPEAK_FIELDS = [:body, :eligibility, :evaluation, :additional_information].freeze

  validate :scheme_dates
  validate :min_must_be_less_than_max
  validates_format_of :continuation_link, with: URI::regexp(%w(http https)), allow_blank: true

  # https://github.com/mongoid/mongoid/issues/1735 Really Mongoid‽
  validates :min_value, :max_value, :max_employees, numericality: { allow_nil: true, only_integer: true }

  scope :for_facets, lambda { |facets|
    where("$and" => facets_criteria(facets)).order_by(priority: :desc, title: :asc)
  }


  def whole_body
    [short_description, body, additional_information].join("\n\n")
  end

  def self.facets_criteria(facets)
    criteria = []
    facets.each do |facet_name, values|
      slugs = values.split(",")
      criteria << { facet_name => { "$in" => slugs } } unless slugs.empty?
    end
    criteria
  end
  private_class_method :facets_criteria

private

  def min_must_be_less_than_max
    if !min_value.nil? && !max_value.nil? && min_value > max_value
      errors[:min_value] << "Min value must be smaller than max value"
      errors[:max_value] << "Max value must be larger than min value"
    end
  end

  def scheme_dates
    errors.add(:start_date, "year must be 4 digits") if start_date.present? && start_date.year.to_s.length != 4
    errors.add(:end_date, "year must be 4 digits") if end_date.present? && end_date.year.to_s.length != 4

    if start_date.present? && end_date.present? && start_date > end_date
      errors.add(:start_date, "can't be later than end date")
    end
  end
end
