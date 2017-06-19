require 'gds_api/publishing_api_v2'

namespace :licence_finder do
  desc "Create draft start page for licence finder"
  task licence_finder_draft: :environment do
    # Claim path
    # https://github.com/alphagov/publishing-api/blob/master/doc/api.md#put-pathsbase_path
    puts "Claiming path /licence-finder"
    endpoint = Services.publishing_api.options[:endpoint_url]
    Services.publishing_api.put_json("#{endpoint}/paths/licence-finder", publishing_app: "publisher", override_existing: true)

    # Delete existing artefact
    # allowing us to create a new one at the right path
    old_artefact = Artefact.where(slug: "licence-finder", owning_app: "licencefinder").first
    if old_artefact
      puts "Deleting existing artefact to allow creating a new one with path /licence-finder"
      old_artefact.delete
    end

    puts "Creating Artefact matching old content_id: 69af22e0-da49-4810-9ee4-22b4666ac627"
    artefact = Artefact.new(
      content_id: "69af22e0-da49-4810-9ee4-22b4666ac627",
      slug: "licence-finder",
      name: "Licence finder",
      owning_app: "publisher",
      kind: "transaction",
      state: "draft",
      language: "en"
    )

    artefact.save!
    puts "Artefact saved"
    puts "Creating Edition from Artefact"

    current_user = User.where(name: "Paul Hayes").first
    edition = Edition.find_or_create_from_panopticon_data(artefact.id.to_s, current_user)
    overview = "Find out which licences you might need for your activity or business"
    link = "/licence-finder/sectors"
    introduction = "You may need a licence for:\r\n\r\n* some business activities\r\n* other activities, eg street parties\r\n\r\nUse this tool to find out which licences you may need."

    edition[:link] = link
    edition[:introduction] = introduction
    edition[:overview] = overview

    edition.save!
    puts "Draft edition created: /editions/#{edition.id}"

    UpdateWorker.perform_async(edition.id.to_s)
    puts "Pushing draft to publishing API: /licence-finder"
  end
end
