require "edition"
require 'gds_api/panopticon'

class Edition
  include BaseHelper

  class ResurrectionError < RuntimeError
  end

  scope :internal_search, lambda { |term|
    regex = Regexp.new(Regexp.escape(term), true)  # case-insensitive
    any_of({title: regex}, {slug: regex}, {overview: regex},
           {alternative_title: regex}, {licence_identifier: regex})
  }

  # Including recipient_id on actions will include anything that has been
  # assigned to the user we're looking at, but include the check anyway to
  # account for manual assignments
  scope :for_user, lambda { |user|
    any_of(
      { assigned_to_id: user.id },
      { 'actions.requester_id' => user.id },
      { 'actions.recipient_id' => user.id }
    )
  }

  scope :user_search, lambda { |user, term|
    all_of(for_user(user).selector, internal_search(term).selector)
  }

  def publish_anonymously
    action_details = published_edition ? { diff: edition_changes } : {}
    if can_publish? && publish
      actions.create!(action_details.merge(request_type: Action::PUBLISH))
      save! # trigger denormalisation callbacks
    else
      false
    end
  end

  alias_method :was_published_without_indexing, :was_published
  def was_published
    was_published_without_indexing
    register_with_panopticon
  end

  def fact_check_skipped?
    actions.any? and actions.last.request_type == 'skip_fact_check'
  end

  def fact_check_email_address
    Publisher::Application.fact_check_config.address(self.id)
  end

  def register_with_panopticon
    artefact = Artefact.find(self.panopticon_id)
    if artefact.state == "archived"
      raise ResurrectionError, "Cannot register archived artefact '#{artefact.slug}'"
    end

    format_as_kind = self.format.underscore
    registerer = GdsApi::Panopticon::Registerer.new(owning_app: "publisher", rendering_app: "frontend", kind: format_as_kind)
    details = RegisterableEdition.new(self)
    registerer.register(details)
  end
end
