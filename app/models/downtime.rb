class Downtime
  include Mongoid::Document
  include Mongoid::Timestamps

  field :message, type: String
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :artefact_id, type: Integer

  # Temp-to-be-brought-back
  # Currently we are using artefact_id as a field to store the artefact id
  # to bypass the issue of having a belongs_to between a postgres table and a mongo table
  # we will most likely bring back the belongs_to relationship once we move Downtime table to postgres.
  # belongs_to :artefact, optional: true

  validate :start_time_precedes_end_time
  validate :end_time_is_in_future
  validates :message, :start_time, :end_time, :artefact, presence: true

  def self.for(artefact)
    where(artefact_id: artefact.id).first
  end

  def publicise?
    Time.zone.now.between?(display_start_time, end_time)
  end

  def display_start_time
    start_time.yesterday.at_midnight
  end

  # Temp-to-be-removed
  # This will be removed once we move Downtime table to postgres, this temporarily
  # allows to support the belongs_to relation between Downtime and Artefact
  def artefact_id=(id)
    self[:artefact_id] = id
  end

  def artefact
    Artefact.find(artefact_id) if artefact_id
  end

private

  def end_time_is_in_future
    errors.add(:end_time, "must be in the future") if end_time && !end_time.future?
  end

  def start_time_precedes_end_time
    errors.add(:start_time, "must be earlier than end time") if start_time && end_time && start_time >= end_time
  end
end
