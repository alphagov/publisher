require "edition"

class LicenceEdition < Edition
  field :licence_identifier, type: String
  field :licence_short_description, type: String
  field :licence_overview, type: String
  field :will_continue_on, type: String
  field :continuation_link, type: String

  GOVSPEAK_FIELDS = [:licence_overview].freeze

  validates :licence_identifier, presence: true
  validate :licence_identifier_unique
  validates_format_of :continuation_link, with: URI::regexp(%w(http https)), allow_blank: true

  def whole_body
    [licence_short_description, licence_overview].join("\n\n")
  end

  def indexable_content
    "#{super} #{licence_short_description} #{Govspeak::Document.new(licence_overview).to_text}".strip
  end

private

  def licence_identifier_unique
    if self.class.where(
      :state.ne => 'archived',
      :licence_identifier => licence_identifier,
      :panopticon_id.ne => panopticon_id
    ).any?
      errors.add(:licence_identifier, :taken)
    end
  end
end
