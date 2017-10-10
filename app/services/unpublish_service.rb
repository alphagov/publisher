class UnpublishService
  class << self
    def call(artefact, user, redirect_url = "")
      if update_artefact_in_shared_db(artefact, user, redirect_url)
        unpublish_in_publishing_api artefact, redirect_url
      end
    end

  private

    def update_artefact_in_shared_db(artefact, user, redirect_url)
      artefact.update_attributes_as(
        user,
        state: "archived",
        redirect_url: redirect_url
      )
    end

    def unpublish_in_publishing_api(artefact, redirect_url)
      if redirect_url.present?
        unpublish_with_redirect(artefact, redirect_url)
      else
        unpublish_without_redirect(artefact)
      end
    end

    def unpublish_with_redirect(artefact, redirect_url)
      if artefact.exact_route?
        unpublish_with_exact_redirect(artefact, redirect_url)
      else
        unpublish_wth_prefix_redirect(artefact, redirect_url)
      end
    end

    def unpublish_with_exact_redirect(artefact, redirect_url)
      Services.publishing_api.unpublish(
        artefact.content_id,
        locale: artefact.language,
        type: 'redirect',
        alternative_path: redirect_url,
        discard_drafts: true
      )
    end

    def unpublish_wth_prefix_redirect(artefact, redirect_url)
      Services.publishing_api.unpublish(
        artefact.content_id,
        locale: artefact.language,
        type: 'redirect',
        redirects: [
          {
            path: "/#{artefact.slug}",
            type: 'prefix',
            destination: redirect_url
          }
        ],
        discard_drafts: true
      )
    end

    def unpublish_without_redirect(artefact)
      Services.publishing_api.unpublish(
        artefact.content_id,
        locale: artefact.language,
        type: 'gone',
        discard_drafts: true
      )
    end
  end
end
