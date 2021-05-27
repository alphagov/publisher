class DevolvedAdministrationAvailability
  include Mongoid::Document

  embedded_in :local_transaction_edition
  field :type, type: String, default: "local_authority_service"
  field :alternative_url, type: String

  validates :type, inclusion: { in: %w[local_authority_service devolved_administration_service unavailable], allow_blank: true }
  validate :alternative_url_presence
  validate :alternative_url_format

  def alternative_url_presence
    if devolved_administration_service_selected? && alternative_url.blank?
      errors.add(:alternative_url, "must be provided")
    end
  end

  def alternative_url_format
    if devolved_administration_service_selected? && alternative_url.present?
      uri = URI.parse(alternative_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:alternative_url, "invalid format")
      end
    end
  end

  def devolved_administration_service_selected?
    type == "devolved_administration_service"
  end
end
