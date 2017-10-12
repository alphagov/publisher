require 'gds_api/router'

class RepublishBusinessSupportEditionsAsPublishingApiRedirectsOrGones < Mongoid::Migration
  def self.up
    business_support_by_state = Artefact.where(kind: 'business_support').group_by(&:state)
    raise "Didn't expect any artefacts not in live, archived, or draft state" unless (business_support_by_state.keys - ['live', 'draft', 'archived']).empty?

    handle_live_business_support_artefacts(business_support_by_state['live'])
    handle_draft_business_support_artefacts(business_support_by_state['draft'])
    handle_archived_business_support_artefacts(business_support_by_state['archived'])
  end

  def self.router
    @router ||= GdsApi::Router.new(Plek.find('router-api'))
  end

  def self.router_response(artefact)
    router.get_route("/#{artefact.slug}").to_hash
  rescue GdsApi::HTTPNotFound
    nil
  end

  def self.publishing_api_response(artefact)
    publishing_api.get_content(artefact.content_id).to_hash
  rescue GdsApi::HTTPNotFound
    nil
  end

  def self.publishing_api
    Services.publishing_api
  end

  def self.down
    # nope, sorry
  end
end
