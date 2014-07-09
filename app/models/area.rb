require "ostruct"
require "gds_api/helpers"

class Area < OpenStruct
  extend GdsApi::Helpers

  AREA_TYPES = ["EUR", "CTY", "DIS", "LBO"]

  def self.all
    areas
  end

  def self.areas_for_edition(edition)
    areas.select { |a| edition.areas.include?(a.slug) }
  end

  def self.regions
    areas.select { |a| a.type == "EUR" }
  end

  def self.english_regions
    regions.select { |r| r.country_name == "England" }
  end

  def slug
    name.parameterize
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
