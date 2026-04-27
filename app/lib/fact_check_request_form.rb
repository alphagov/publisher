class FactCheckRequestForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  SOURCE_APP = "publisher".freeze

  attr_accessor :edition, :user

  attribute :email_addresses, :string
  attribute :deadline, :date
  attribute :reason_for_change, :string, default: nil
  # If this is typecast to integer, then non-integer values would be cast to 0 and accepted. Numericality handles non-int strings.
  attribute :zendesk_number, :string, default: nil

  validates :edition, :user, presence: true
  validates :deadline, presence: { message: "Enter a deadline" }, on: :send
  validates :email_addresses, presence: { message: "Enter one or more email addresses" }, on: :send
  validates :zendesk_number, numericality: { only_integer: true,
                                             greater_than: 999_999,
                                             message: "Zendesk number must be a number at least 7 digits long",
                                             allow_blank: true }, on: :send

  validate :user_has_editor_permissions
  validate :valid_email_addresses, on: :send
  validate :deadline_in_range, on: :send

  def request_fact_check
    return false unless valid?(:send)

    Services.fact_check_manager_api.post_fact_check(**post_payload)
  end

  def resend_fact_check_emails
    return false unless valid?(:resend)

    Services.fact_check_manager_api.post_resend_emails(source_app: SOURCE_APP, source_id: edition.id)
  end

  def update_fact_check_content
    return false unless valid?(:update)

    Services.fact_check_manager_api.patch_update_content(**update_content_payload)
  end

private

  def user_has_editor_permissions
    return if user.blank?

    errors.add(:user, "You do not have permission to edit this content") unless user.has_editor_permissions?(edition)
  end

  def valid_email_addresses
    return if email_addresses.blank?

    email_regex = /\A[\w+\-%.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/
    if split_email_addresses.any? { |address| address.strip !~ email_regex }
      errors.add(:email_addresses, "Email addresses are invalid")
    end
  end

  def deadline_in_range
    return if deadline.blank?

    if deadline < Date.current || deadline > 30.days.from_now
      errors.add(:deadline, "The date must be today or up to 30 days in the future")
    end
  end

  def split_email_addresses
    return if email_addresses.blank?

    email_addresses.split(Regexp.union(",", ";")).map(&:strip)
  end

  def current_content_presenter
    @current_content_presenter ||= Formats::GenericEditionPresenter.new(edition)
  end

  def previous_content_presenter
    return nil unless edition&.published_edition

    @previous_content_presenter ||= Formats::GenericEditionPresenter.new(edition.published_edition)
  end

  def post_payload
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

  def update_content_payload
    {
      source_app: SOURCE_APP,
      source_id: edition.id,
      source_title: edition.title,
      current_content: current_content_presenter.render_for_fact_check_manager_api,
      draft_auth_bypass_id: @edition.auth_bypass_id,
      draft_slug: @edition.slug,
    }
  end
end
