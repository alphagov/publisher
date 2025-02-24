class Event
  field :title, type: String
  field :date, type: Date
  field :notes, type: String
  field :bunting_type, type: String
end

class CalendarYear
  field :year, type: Integer

  embeds_many :events
end

class BankHolidaysEdition < Edition
  include Mongoid::Document
  field :division, type: Array
  field :year, type: Array
  field :event, type: Array

  # Note: Can add 'validate' methods here, do we need any?

  # def create_draft_bank_holidays_from_last_record
  #   last_bank_holidays = BankHolidaysEdition.last
  #   bank_holidays = BankHolidaysEdition.new(year: last_bank_holidays.year, event: last_bank_holidays.event, version_number: last_bank_holidays.version_number.next)
  #   bank_holidays.save!
  #   bank_holidays
  # end
  #
  # GOVSPEAK_FIELDS = [:body].freeze
  #
  # def publish_latest
  #   save_draft if is_draft?
  #   Services.publishing_api.publish(content_id, update_type, locale:)
  #   publish
  # end

  def save_draft
    UpdateService.call(self)
    save!
  end

  def content_id
    "58f79dbd-e57f-4ab2-ae96-96df5767d1b2".freeze
  end

  def update_type
    "major".freeze
  end

  def locale
    "en".freeze
  end

  def can_delete?
    is_draft?
  end

private

  def is_draft?
    state == "draft"
  end
end