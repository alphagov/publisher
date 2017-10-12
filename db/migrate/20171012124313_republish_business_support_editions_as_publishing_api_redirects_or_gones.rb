require 'gds_api/router'

class RepublishBusinessSupportEditionsAsPublishingApiRedirectsOrGones < Mongoid::Migration
  def self.up
    business_support_by_state = Artefact.where(kind: 'business_support').group_by(&:state)
    raise "Didn't expect any artefacts not in live, archived, or draft state" unless (business_support_by_state.keys - ['live', 'draft', 'archived']).empty?

    handle_live_business_support_artefacts(business_support_by_state['live'])
    handle_draft_business_support_artefacts(business_support_by_state['draft'])
    handle_archived_business_support_artefacts(business_support_by_state['archived'])
  end

  def self.handle_draft_business_support_artefacts(draft_artefacts)
    raise "Didn't expect any editions for draft artefacts" if draft_artefacts.any? { |a| a.latest_edition.present? }
    raise "Didn't expect any entries in router for draft artefacts" if draft_artefacts.any? { |a| router_response(a).present? }
    raise "Didn't expect any entries in publishing-api for draft artefacts" if draft_artefacts.any? { |a| publishing_api_response(a).present? }

    Artefact.skip_callback(:destroy, :before, :discard_publishing_api_draft)
    say_with_time "Removing #{draft_artefacts.size} draft artefacts" do
      draft_artefacts.each { |a| a.destroy }
    end
    Artefact.set_callback(:destroy, :before, :discard_publishing_api_draft)
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
