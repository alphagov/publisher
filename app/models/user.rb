require "digest/md5"
require "cgi"
require "gds-sso/user"
require_dependency "safe_html"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User

  # Let an app configure the symbolized collection name to use,
  # e.g. set a constant in an initializer.
  if defined?(USER_COLLECTION_NAME)
    store_in collection: USER_COLLECTION_NAME.to_sym
  else
    store_in collection: :users
  end

  field "name",                    type: String
  field "uid",                     type: String
  field "version",                 type: Integer
  field "email",                   type: String
  field "permissions",             type: Array, default: []
  field "remotely_signed_out",     type: Boolean, default: false
  field "organisation_slug",       type: String
  field "disabled",                type: Boolean, default: false
  field "organisation_content_id", type: String

  index({ uid: 1 }, unique: true)
  index disabled: 1

  scope :alphabetized, -> { order_by(name: :asc) }
  scope :enabled,
        lambda {
          any_of(
            { :disabled.exists => false },
            { :disabled.in => [false, nil] },
          )
        }

  def to_s
    name || email || ""
  end

  def progress(edition, action_attributes)
    request_type = action_attributes.delete(:request_type)

    processor = GovukContentModels::ActionProcessors::REQUEST_TYPE_TO_PROCESSOR[request_type.to_sym]
    edition = GovukContentModels::ActionProcessors.const_get(processor).new(self, edition, action_attributes, {}).processed_edition
    edition.save! if edition
  end

  def record_note(edition, comment, type = Action::NOTE)
    edition.new_action(self, type, comment:)
  end

  def resolve_important_note(edition)
    record_note(edition, nil, Action::IMPORTANT_NOTE_RESOLVED)
  end

  def create_edition(format, attributes = {})
    GovukContentModels::ActionProcessors::CreateEditionProcessor.new(self, nil, {}, format:, edition_attributes: attributes).processed_edition
  end

  def new_version(edition, convert_to = nil)
    GovukContentModels::ActionProcessors::NewVersionProcessor.new(self, edition, {}, convert_to:).processed_edition
  end

  def assign(edition, recipient)
    return unless has_editor_permissions?(edition) && recipient.has_editor_permissions?(edition)

    GovukContentModels::ActionProcessors::AssignProcessor.new(self, edition, recipient_id: recipient.id).processed_edition
  end

  def unassign(edition)
    GovukContentModels::ActionProcessors::AssignProcessor.new(self, edition).processed_edition
  end

  def govuk_editor?
    permissions.include?("govuk_editor")
  end

  def welsh_editor?
    permissions.include?("welsh_editor")
  end

  def departmental_editor?
    permissions.include?("departmental_editor")
  end

  def has_editor_permissions?(resource)
    govuk_editor? || (welsh_editor? && resource.artefact.welsh?)
  end

  def gds_editor?
    organisation_content_id == PublishService::GDS_ORGANISATION_ID
  end
end
