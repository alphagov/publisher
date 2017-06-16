require 'attachable'
require 'edition'

class CampaignEdition < Edition
  include Attachable

  field :body, type: String
  field :organisation_formatted_name, type: String
  field :organisation_url, type: String
  field :organisation_brand_colour, type: String
  field :organisation_crest, type: String

  attaches :large_image, :medium_image, :small_image

  GOVSPEAK_FIELDS = [:body].freeze

  BRAND_COLOURS = [
    "attorney-generals-office",
    "cabinet-office",
    "department-for-business-innovation-skills",
    "department-for-communities-and-local-government",
    "department-for-culture-media-sport",
    "department-for-education",
    "department-for-environment-food-rural-affairs",
    "department-for-international-development",
    "department-for-transport",
    "department-for-work-pensions",
    "department-of-energy-climate-change",
    "department-of-health",
    "foreign-commonwealth-office",
    "hm-government",
    "hm-revenue-customs",
    "hm-treasury",
    "home-office",
    "ministry-of-defence",
    "ministry-of-justice",
    "northern-ireland-office",
    "office-of-the-advocate-general-for-scotland",
    "office-of-the-leader-of-the-house-of-lords",
    "scotland-office",
    "the-office-of-the-leader-of-the-house-of-commons",
    "uk-export-finance",
    "uk-trade-investment",
    "wales-office"
  ].freeze
  CRESTS = {
    "No identity" => "no-identity",
    "Single identity" => "single-identity",
    "Department for Business, Innovation and Skills" => "bis",
    "Scotland Office" => "so",
    "Home Office" => "ho",
    "Ministry of Defence" => "mod",
    "Wales Office" => "wales",
    "HM Coastguard" => "coastguard",
    "Portcullis" => "portcullis",
    "UK Hydrographic Office" => "ukho",
    "Executive Office" => "eo",
    "HM Revenue and Customs" => "hmrc",
    "UK Atomic Energy Authority" => "ukaea"
  }.freeze

  validates :organisation_brand_colour, inclusion: { in: BRAND_COLOURS, allow_blank: true }
  validates :organisation_crest, inclusion: { in: CRESTS.values, allow_blank: true }
  validates_with SafeHtml

  def whole_body
    self.body
  end
end
