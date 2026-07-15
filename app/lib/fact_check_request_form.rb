class FactCheckRequestForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  SOURCE_APP = "publisher".freeze

  attr_accessor :edition, :user

  attribute :email_addresses, :string

  attribute :deadline_1i, :string
  attribute :deadline_2i, :string
  attribute :deadline_3i, :string
  attribute :reason_for_change, :string, default: nil
  attribute :zendesk_number, :string, default: nil

  validates :email_addresses, presence: { message: "Enter one or more email addresses" }, on: :send

  validate :valid_zendesk_number, on: :send
  validate :valid_email_addresses, on: :send
  validate :deadline_in_range, on: :send
  validate :deadline_present, on: :send

  EMAIL_REGEX = /\A[\w+\-%.']+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/
  ZENDESK_NUMBER_REGEX = /\A\d{7,}\z/

  def zendesk_number=(value)
    value = value.strip.delete_prefix("#").strip if value.is_a?(String)
    super
  end

  def deadline
    return unless deadline_1i.present? && deadline_2i.present? && deadline_3i.present?

    Date.new(deadline_1i.to_s.to_i, deadline_2i.to_s.to_i, deadline_3i.to_s.to_i)
  rescue Date::Error
    nil
  end

  def post_new_request_payload
    { source_app: SOURCE_APP,
      source_id: edition.id,
      source_url: "#{Plek.find('publisher', external: true)}/editions/#{edition.id}",
      source_title: edition.title,
      requester_name: user.name,
      requester_email: user.email,
      current_content: current_content_presenter.render_for_fact_check_manager_api,
      previous_content: previous_content_presenter&.render_for_fact_check_manager_api,
      deadline: deadline.iso8601,
      reason_for_change: reason_for_change,
      recipients: split_email_addresses,
      zendesk_number: zendesk_number,
      draft_content_id: @edition.content_id,
      draft_auth_bypass_id: @edition.auth_bypass_id,
      draft_slug: @edition.slug }
  end

  def resend_emails_payload
    {
      source_app: SOURCE_APP,
      source_id: edition.id,
    }
  end

  def update_content_payload
    {
      source_app: SOURCE_APP,
      source_id: edition.id,
      source_title: edition.title,
      current_content: current_content_presenter.render_for_fact_check_manager_api,
      draft_auth_bypass_id: edition.auth_bypass_id,
      draft_slug: edition.slug,
    }
  end

private

  def user_has_editor_permissions
    return if user.blank?

    errors.add(:user, "You do not have permission to edit this content") unless user.has_editor_permissions?(edition)
  end

  def valid_email_addresses
    return if email_addresses.blank?

    if split_email_addresses.any? { |address| !address.to_s.strip.match?(EMAIL_REGEX) }
      errors.add(:email_addresses, "Email addresses are invalid")
    end
  end

  def valid_zendesk_number
    return if zendesk_number.blank?

    if !zendesk_number.match?(ZENDESK_NUMBER_REGEX)
      errors.add(:zendesk_number, "Zendesk ticket number must be at least 7 digits long")
    elsif zendesk_number.start_with?("0")
      errors.add(:zendesk_number, "Zendesk ticket numbers cannot start with zero")
    end
  end

  def deadline_in_range
    return if deadline.blank?

    if deadline < Date.current || deadline > 30.days.from_now
      errors.add(:deadline, "The date must be today or up to 30 days in the future")
    end
  end

  def deadline_present
    errors.add(:deadline, "Enter a deadline") if deadline.blank?
  end

  def split_email_addresses
    return if email_addresses.blank?

    email_addresses.split(Regexp.union(",", ";")).map(&:strip)
  end

  def current_content_presenter
    @current_content_presenter ||= EditionPresenterFactory.get_presenter(edition)
  end

  def previous_content_presenter
    return nil unless edition&.published_edition

    @previous_content_presenter ||= EditionPresenterFactory.get_presenter(edition.published_edition)
  end
end
