module Editionable
  extend ActiveSupport::Concern

  included do
    has_one :edition, as: :editionable

    validates_with SafeHtml, unless: :popular_links_edition?
    validates_with LinkValidator, on: :update, unless: :archiving_or_popular_links?

    delegate :major_change, :change_note, :overview, :latest_status_action, :panopticon_id, :title, :version_number, :state, :auth_bypass_id, :publish_popular_links, :assigned_to_id, :in_beta, :reviewer, to: :edition
  end

  def popular_links_edition?
    instance_of?(::PopularLinksEdition)
  end

  def archiving_or_popular_links?
    archiving? || popular_links_edition?
  end

  def archiving?
    edition.state_events == [:archive]
  end

  def draft?
    edition.state == "draft"
  end

  def published?
    edition.state == "published"
  end
end
