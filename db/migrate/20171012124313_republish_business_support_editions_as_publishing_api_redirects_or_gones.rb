require 'gds_api/router'

class RepublishBusinessSupportEditionsAsPublishingApiRedirectsOrGones < Mongoid::Migration
  def self.up
    business_support_by_state = Artefact.where(kind: 'business_support').group_by(&:state)
    raise "Didn't expect any artefacts not in live, archived, or draft state" unless (business_support_by_state.keys - ['live', 'draft', 'archived']).empty?

    handle_live_business_support_artefacts(business_support_by_state['live'])
    handle_draft_business_support_artefacts(business_support_by_state['draft'])
    handle_archived_business_support_artefacts(business_support_by_state['archived'])
  end

  def self.handle_live_business_support_artefacts(live_artefacts)
    # 1. Exclude 'jobcentre-plus-vacancy-filling-system-uk' as it's already
    #    been redirected by short-url-manager
    live_artefacts = handle_jobcentre_plus_vacancy_filling_system_uk(live_artefacts)

    # 2. Set the appropriate redirects from router-data as the redirect_uri on
    #    the Artefact or set general purpose redirect_uri of
    #    /business-finance-support if it's not currently a redirect
    say_with_time "Checking #{live_artefacts.size} live artefacts status in router & publishing-api" do
      live_artefacts.each do |live_artefact|
        content_id = publishing_api.lookup_content_id(base_path: "/#{live_artefact.slug}", exclude_unpublishing_types: [], exclude_document_types: [])
        raise "Didn't expect publishing-api to think some other content_id is the owner of a live artefact's path (#{live_artefact.slug}, #{live_artefact.content_id}, #{content_id})" if live_artefact.content_id != content_id
        content_item = publishing_api.get_content(content_id).to_hash
        raise "Didn't expect publishing-api content for live artefact not to be a business_support (#{live_artefact.slug}, #{live_artefact.content_id}, #{content_item['document_type']})" if content_item['document_type'] != 'business_support'
        current_route = router_response(live_artefact)
        raise "Didn't exxpect any live artefacts not to have a route in router-api (#{live_artefact.slug}, #{live_artefact.content_id})" if current_route.nil?

        if current_route['handler'] == 'redirect'
          live_artefact.redirect_url = current_route['redirect_to']
        else
          live_artefact.redirect_url = '/business-finance-support'
        end
      end
    end

    # 3. Use UnpublishService to generate a publishing-api redirect
    say_with_time "Unpublishing #{live_artefacts.size} live artefacts as redirects via publishing-api" do
      live_artefacts.each do |live_artefact|
        UnpublishService.call(live_artefact, nil, live_artefact.redirect_url)
      end
    end
  end

  def self.handle_jobcentre_plus_vacancy_filling_system_uk(live_artefacts)
    jobcentre_plus_vacany_fill_system_uk = live_artefacts.detect { |x| x.slug = 'jobcentre-plus-vacancy-filling-system-uk'}
    raise "Didn't expect 'jobcentre-plus-vacancy-filling-system-uk' to be missing from live business support artefacts" if jobcentre_plus_vacany_fill_system_uk.nil?

    say_with_time "Checking 'jobcentre-plus-vacancy-filling-system-uk' is already migrated by short-url-manager" do
      content_id = publishing_api.lookup_content_id(base_path: "/jobcentre-plus-vacancy-filling-system-uk", exclude_unpublishing_types: [], exclude_document_types: [])
      raise "Didn't expect publishing-api to think artefact is the content_id for /jobcentre-plus-vacancy-filling-system-uk path" if jobcentre_plus_vacany_fill_system_uk.content_id == content_id
      content_item = publishing_api.get_content(content_id).to_hash
      raise "Didn't expect publishing-api content for /jobcentre_plus_vacany_fill_system_uk not to be a redirect" if content_item['document_type'] != 'redirect'
    end
    live_artefacts.reject { |x| x.slug == jobcentre_plus_vacany_fill_system_uk.slug }
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
