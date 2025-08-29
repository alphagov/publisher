require "digest/md5"
require "cgi"
require "gds-sso/user"
require_dependency "safe_html"

class User < ApplicationRecord
  include GDS::SSO::User

  has_many :artefact_actions, class_name: "ArtefactAction"

  scope :alphabetized, -> { order(name: :asc) }
  scope :enabled, -> { where("disabled IS NULL OR disabled = ?", false) }

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

  def role
    if gds_editor? then "GDS Editor"
    elsif govuk_editor? then "GOVUK Editor"
    elsif departmental_editor? then "Departmental Editor"
    elsif welsh_editor? then "Welsh Editor"
    elsif skip_review? then "Skip Review"
    else
      "Writer"
    end
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

  def skip_review?
    permissions.include?("skip_review")
  end
end
