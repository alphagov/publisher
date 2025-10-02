class DevolvedAdministrationAvailability < ApplicationRecord
  validates :authority_type, inclusion: { in: %w[local_authority_service devolved_administration_service unavailable] }
  validates :alternative_url, presence: { message: "Enter the URL of the devolved administration website page" }, if: -> { devolved_administration_service? }
  validate :alternative_url_format

  def alternative_url_format
    return if alternative_url.blank?

    uri = begin
      URI.parse(alternative_url)
    rescue URI::Error
      nil
    end

    unless uri.is_a?(URI::HTTPS)
      errors.add(:alternative_url, "Must be a full URL, starting with https://")
    end
  end

  def devolved_administration_service?
    authority_type == "devolved_administration_service"
  end
end
