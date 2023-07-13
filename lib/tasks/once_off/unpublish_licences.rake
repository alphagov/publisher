PATHS_NOT_TO_MIGRATE = [
  "hazardous-waste-producer-registration-wales",
  "licence-to-photograph-wildlife-northern-ireland",
  "auctioneer-s-permit-firearms-and-ammunition-northern-ireland",
  "petroleum-exploration-licence-northern-ireland",
  "chaperone-licence-northern-ireland",
  "voluntary-registration-as-state-registered-hairdresser-england-scotland-wales",
  "slaughterman-licence-northern-ireland",
  "sqa-qualifications-approval-scotland",
  "sports-ground-safety-certificate-england-scotland-and-wales",
  "safety-certificates-for-sports-grounds",
  "safety-certificates-for-regulated-stands-at-sports-grounds-e-s-w",
  "safety-certificates-for-regulated-stands-at-sports-grounds",
  "private-hire-vehicle-licence-scotland",
  "hackney-carriage-vehicle-licence",
  "performing-animals-registration-wales-scotland",
  "pet-shop-licence-wales-scotland",
].freeze

namespace :once_off do
  desc "Archives and unpublishes licences after they've been migrated to Specialist Publisher"
  task unpublish_licences: :environment do
    LicenceEdition.where(state: "published").each do |licence_edition|
      if licence_edition.exact_route?
        puts("WARNING: #{licence_edition.slug} skipped as it unexpectedly has an exact route")
        next
      end

      redirect_url = PATHS_NOT_TO_MIGRATE.include?(licence_edition.slug) ? nil : "/find-licences/#{licence_edition.slug}"
      artefact = licence_edition.artefact

      artefact.assign_attributes(state: "archived", redirect_url:)
      artefact.save_as_task!("once_off:unpublish_licences")

      if redirect_url.present?
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
        puts("#{licence_edition.slug} archived, unpublished with redirect to #{redirect_url}")
      else
        Services.publishing_api.unpublish(
          artefact.content_id,
          locale: artefact.language,
          type: "gone",
          discard_drafts: true,
        )
        puts("#{licence_edition.slug} archived, unpublished without redirect}")
      end
    end
  end
end
