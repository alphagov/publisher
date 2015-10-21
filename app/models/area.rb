require "ostruct"
require "gds_api/helpers"

class Area < OpenStruct
  extend GdsApi::Helpers

  # This list should stay in sync with Business Support API's
  # WHITELISTED_AREA_CODES list:
  # (https://github.com/alphagov/business-support-api/blob/master/app/models/scheme.rb#L8-L10).
  AREA_TYPES = ["EUR", "CTY", "DIS", "LBO", "LGD", "MTD", "UTA"]

  def self.all
    areas
  end

  def self.areas_for_edition(edition)
    areas.select { |a| edition.area_gss_codes.include?(a.codes["gss"]) }
  end

  def self.regions
    areas.select { |a| a.type == "EUR" }
  end

  def self.english_regions
    regions.select { |r| r.country_name == "England" }
  end

  private

    def self.areas
      @areas ||= all_areas
    end

    def self.all_areas
      areas = []
      AREA_TYPES.each do |type|
        areas << imminence_api.areas_for_type(type)["results"].map do |area_hash|
          self.new(area_hash)
        end
      end
      areas.flatten
    end
end
