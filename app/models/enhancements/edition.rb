require "edition"
require 'gds_api/panopticon'

class Edition
  include Admin::BaseHelper

  class ResurrectionError < RuntimeError
  end

  alias_method :was_published_without_indexing, :was_published
  def was_published
    was_published_without_indexing
    register_with_panopticon
  end

  def fact_check_skipped?
    actions.any? and actions.last.request_type == 'skip_fact_check'
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
