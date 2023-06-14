namespace :once_off do
  desc "Archives and unpublishes the licence finder, redirecting to the new one"
  task unpublish_licence_finder: :environment do
    licence_finder_edition = Edition.where(state: "published", slug: "licence-finder").last
    artefact = licence_finder_edition.artefact
    redirect_url = "/find-licences"

    artefact.assign_attributes(state: "archived", redirect_url:)
    artefact.save_as_task!("once_off:unpublish_licence_finder")

    Services.publishing_api.unpublish(
      artefact.content_id,
      locale: artefact.language,
      type: "redirect",
      redirects: [
        {
          path: "/#{artefact.slug}",
          type: "prefix",
          destination: redirect_url,
          segments_mode: "ignore",
        },
      ],
      discard_drafts: true,
    )
    puts("#{licence_finder_edition.slug} archived, unpublished with redirect to #{redirect_url}")
  end
end
