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

  def self.handle_archived_business_support_artefacts(archived_artefacts)
    archived_artects_and_router_responses = say_with_time "Fetching router response for archived_artefacts" do
      archived_artefacts.map { |a| [a, router_response(a)] }
    end

    archived_artefacts_by_router_availabilty = archived_artects_and_router_responses.group_by { |(a, r)| r.present? }

    handle_archived_business_support_artefacts_in_router(archived_artefacts_by_router_availabilty.fetch(true, []))
    handle_archived_business_support_artefacts_not_in_router(archived_artefacts_by_router_availabilty.fetch(false, []))
  end

  def self.handle_archived_business_support_artefacts_in_router(archived_artefacts_in_router)
    raise "Didn't expect there to be no archived artefacts in the router" if archived_artefacts_in_router.empty?
    archived_artefacts_by_router_handler = archived_artefacts_in_router.group_by { |(a, r)| r['handler'] }
    raise "Didn't expect archived artefacts with a router handler other than 'redirect', 'gone', 'backend'" unless (archived_artefacts_by_router_handler.keys - ['redirect', 'gone', 'backend']).empty?

    handle_archived_business_support_artefacts_redirected_in_router(archived_artefacts_by_router_handler.fetch('redirect', []))
    handle_archived_business_support_artefacts_gone_in_router(archived_artefacts_by_router_handler.fetch('gone', []))
    handle_archived_business_support_artefacts_live_in_router(archived_artefacts_by_router_handler.fetch('backend', []))
  end

  def self.handle_archived_business_support_artefacts_redirected_in_router(redirected_archived_artefacts_and_router_responses)
    # 1. For the redirects
    #   a) set redirect_uri according to this result (we need to cross reference this with router-data)
    #   b) if the artefact's content_id is in publishing-api already push the
    #      artefact through UnpublishService to create a publishing-api redirect
    #   c) if the artefact's content_id is not in publishing-api already send
    #      a new content_item of type redirect
    raise "Didn't expect there to be no archived artefacts stored as redirects in the router" if redirected_archived_artefacts_and_router_responses.empty?

    say_with_time "Unpublishing #{redirected_archived_artefacts_and_router_responses.size} archived artefacts listed as redirects in the router as redirects via publishing-api" do
      redirected_archived_artefacts_and_router_responses.each do |(artefact, router_response)|
        artefact.redirect_url = router_response['redirect_to']
        if publishing_api_response(artefact).present?
          UnpublishService.call(artefact, nil, artefact.redirect_url)
        else
          create_redirect_item_in_publishing_api(artefact)
        end
      end
    end
  end

  def self.handle_archived_business_support_artefacts_gone_in_router(gone_archived_artefacts_and_router_responses)
    # 2. For the gones
    #   a) leave redirect_uri alone
    #   b) if the artefact's content_id is in publishing-api already push the
    #      artefact through UnpublishService to create a publishing-api gone
    #   c) if the artefact's content_id is not in publishing-api already send
    #      a new content_item of type gone
    raise "Didn't expect there to be no archived artefacts stored as gones in the router" if gone_archived_artefacts_and_router_responses.empty?

    say_with_time "Unpublishing #{gone_archived_artefacts_and_router_responses.size} archived artefacts listed as gone items in the router as gone items via publishing-api" do
      gone_archived_artefacts_and_router_responses.each do |(artefact, _router_response)|
        if publishing_api_response(artefact).present?
          UnpublishService.call(artefact, nil, nil)
        else
          create_gone_item_in_publishing_api(artefact)
        end
      end
    end
  end

  def self.handle_archived_business_support_artefacts_live_in_router(live_archived_artefacts_and_router_responses)
    # 3. For the live ones
    #   a) set redirect_uri to the default `/business-finance-support`
    #   b) if the artefact's content_id is in publishing-api already push the
    #      artefact through UnpublishService to create a publishing-api redirect
    #   c) if the artefact's content_id is not in publishing-api already send
    #      break as we don't expect any of these
    raise "Didn't expect there to be no archived artefacts stored as live in the router" if live_archived_artefacts_and_router_responses.empty?

    say_with_time "Unpublishing #{live_archived_artefacts_and_router_responses.size} archived artefacts still listed as live by the router as redirects to '/business-finance-support' via publishing-api" do
      live_archived_artefacts_and_router_responses.each do |(artefact, _router_responses)|
        if publishing_api_response(artefact).present?
          UnpublishService.call(artefact, nil, '/business-finance-support')
        else
          raise "Didn't expect any archived artefacts listed as live routes in router to not have content items in the publishing-api"
        end
      end
    end
  end

  def self.handle_archived_business_support_artefacts_not_in_router(archived_artefacts_not_in_router_and_router_responses)
    archived_artefacts_not_in_router = archived_artefacts_not_in_router_and_router_responses.map { |(a, _r)| a }
    raise "Didn't expect there to be no archived artefacts missing from the router" if archived_artefacts_not_in_router.empty?

    archived_editions_not_in_router_by_edition_presence = archived_artefacts_not_in_router.group_by { |a| a.latest_edition.present? }

    handle_archived_business_support_artefacts_not_in_router_with_editions(archived_editions_not_in_router_by_edition_presence.fetch(true, []))
    handle_archived_business_support_artefacts_not_in_router_with_no_editions(archived_editions_not_in_router_by_edition_presence.fetch(false, []))
  end

  def self.handle_archived_business_support_artefacts_not_in_router_with_editions(archived_editions_with_editions)
    raise "Didn't expect there to be no archived artefacts missing from the router without editions" if archived_editions_with_editions.empty?

    archived_editions_with_editions_by_publish_event_presence = archived_editions_with_editions.group_by { |a| Edition.where(panopticon_id: a.id).flat_map { |e| e.actions.map(&:request_type) }.uniq.include?('publish') }

    handle_archived_business_support_artefacts_not_in_router_with_editions_published(archived_editions_with_editions_by_publish_event_presence.fetch(true, []))
    handle_archived_business_support_artefacts_not_in_router_with_editions_never_published(archived_editions_with_editions_by_publish_event_presence.fetch(false, []))
  end

  def self.handle_archived_business_support_artefacts_not_in_router_with_editions_published(archived_artefacts_been_published)
    # If it's archived and has editions and we've recorded a publish event
    # then it's like a live one that's missing from the publishing-api so we
    # should issue a redirect content_item for it
    raise "Didn't expect there to be no archived artefacts missing from the router with editions that had been published" if archived_artefacts_been_published.empty?
    raise "Didn't expect any entries in publishing-api for archived artefacts missing from the router with editions that had been published" if archived_artefacts_been_published.any? { |a| publishing_api_response(a).present? }

    say_with_time "Unpublishing #{archived_artefacts_been_published.size} archived artefacts missing from the router that have editions and have been published before (but are not in the publishing-api) as redirects to '/business-finance-support' via publishing-api" do
      archived_artefacts_been_published.each do |artefact|
        artefact.update_attributes_as(nil, state: "archived", redirect_url: '/business-finance-support')
        create_redirect_item_in_publishing_api(artefact)
      end
    end
  end

  def self.handle_archived_business_support_artefacts_not_in_router_with_editions_never_published(archived_artefacts_never_published)
    # If it's archived and has editions but we've not recorded a publish event
    # then it's similar to a draft - it's never been published and we can just
    # delete it
    raise "Didn't expect there to be no archived artefacts missing from the router with editions that had never been published" if archived_artefacts_never_published.empty?
    raise "Didn't expect any entries in publishing-api for archived artefacts missing from the router with editions that had never been published" if archived_artefacts_never_published.any? { |a| publishing_api_response(a).present? }

    Artefact.skip_callback(:destroy, :before, :discard_publishing_api_draft)
    say_with_time "Removing #{archived_artefacts_never_published.size} archived artefacts missing from the router that have editions, but have never been published" do
      archived_artefacts_never_published.each { |a| a.destroy }
    end
    Artefact.set_callback(:destroy, :before, :discard_publishing_api_draft)
  end

  def self.handle_archived_business_support_artefacts_not_in_router_with_no_editions(archived_artefacts_with_no_editions)
    # If it's archived and has no editions then it's similar to a draft - it's
    # never been published and we can just delete it
    raise "Didn't expect there to be no archived artefacts missing from the router without editions" if archived_artefacts_with_no_editions.empty?
    raise "Didn't expect any entries in publishing-api for archived artefacts missing from the router without editions" if archived_artefacts_with_no_editions.any? { |a| publishing_api_response(a).present? }

    Artefact.skip_callback(:destroy, :before, :discard_publishing_api_draft)
    say_with_time "Removing #{archived_artefacts_with_no_editions.size} archived artefacts missing from the router that have no editions" do
      archived_artefacts_with_no_editions.each { |a| a.destroy }
    end
    Artefact.set_callback(:destroy, :before, :discard_publishing_api_draft)
  end

  def self.create_redirect_item_in_publishing_api(artefact)
    publishing_api.put_content(
      artefact.content_id,
      {
        "base_path" => "/#{artefact.slug}",
        "document_type" => "redirect",
        "schema_name" => "redirect",
        "publishing_app" => "publisher",
        "update_type" => "major",
        "redirects" => [
          {
            "path" => "/#{artefact.slug}",
            "type" => artefact.exact_route? ? 'exact' : 'prefix',
            "destination" => artefact.redirect_url,
          },
        ],
      }
    )
    publishing_api.publish(artefact.content_id)
  end

  def self.create_gone_item_in_publishing_api(artefact)
    publishing_api.put_content(
      artefact.content_id,
      {
        "base_path" => "/#{artefact.slug}",
        "document_type" => "gone",
        "schema_name" => "gone",
        "publishing_app" => "publisher",
        "update_type" => "major",
        "routes" => [
          {
            "path" => "/#{artefact.slug}",
            "type" => artefact.exact_route? ? 'exact' : 'prefix',
          },
        ],
      }
    )
    publishing_api.publish(artefact.content_id)
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
