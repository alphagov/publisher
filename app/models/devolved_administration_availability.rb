class DevolvedAdministrationAvailability
  # include Mongoid::Document

  has_many :local_transaction_edition
  field :type, type: String, default: "local_authority_service"
  field :alternative_url, type: String

  validates :type, inclusion: { in: %w[local_authority_service devolved_administration_service unavailable] }
  validates :alternative_url, presence: true, if: -> { devolved_administration_service? }
  validate :alternative_url_format

  def alternative_url_format
    return if alternative_url.blank?

    uri = begin
      URI.parse(alternative_url)
    rescue URI::Error
      nil
    end

    unless uri.is_a?(URI::HTTPS)
      errors.add(:alternative_url, "must be a full URL, starting with https://")
    end
  end

  def devolved_administration_service?
    type == "devolved_administration_service"
  end
end
