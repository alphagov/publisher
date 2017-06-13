require 'gds_api/publishing_api_v2'

namespace :calculators do
  desc "Claim /child-benefit-tax-calculator path and allow new transaction to be created"
  task claim_calculator: :environment do
    # Claim child benefit tax calculator path from calculators
    # https://github.com/alphagov/publishing-api/blob/master/doc/api.md#put-pathsbase_path
    puts "Claiming path /child-benefit-tax-calculator"
    endpoint = Services.publishing_api.options[:endpoint_url]
    Services.publishing_api.put_json("#{endpoint}/paths/child-benefit-tax-calculator", publishing_app: "publisher", override_existing: true)
  end

  desc "Create draft start page for child benefit tax calculator"
  task calculator_draft: :environment do
    # Delete existing artefact for child benefit tax calculator
    # allowing us to create a new one at the right path
    old_artefact = Artefact.where(slug: "child-benefit-tax-calculator", owning_app: "calculators").first
    if old_artefact
      puts "Deleting existing calculator artefact to allow creating a new one with path /child-benefit-tax-calculator"
      old_artefact.delete
    end

    puts "Creating Artefact matching old content_id: 0e1de8f1-9909-4e45-a6a3-bffe95470275"
    artefact = Artefact.new(
      content_id: "0e1de8f1-9909-4e45-a6a3-bffe95470275",
      slug: "child-benefit-tax-calculator",
      name: "Child Benefit tax calculator",
      owning_app: "publisher",
      kind: "transaction",
      state: "draft",
      language: "en",
      need_id: "100266",
      need_ids: %w(100266 100669)
    )

    artefact.save!
    puts "Artefact saved"
    puts "Creating Edition from Artefact"

    current_user = User.where(name: "Paul Hayes").first
    edition = Edition.find_or_create_from_panopticon_data(artefact.id.to_s, current_user)
    overview = "Work out the Child Benefit you've received and your High Income Child Benefit tax charge"
    link = "/child-benefit-tax-calculator/main"
    introduction = "Use this tool to work out:\r\n\r\n* how much Child Benefit you receive in a tax year\r\n* the High Income Child Benefit tax charge you or your partner may have to pay"
    more_information = "You may be affected by the tax charge if your income is over £50,000.\r\n\r\nYour partner is responsible for paying the tax charge if their income is more than £50,000 and higher than yours.\n\nYou’ll need the dates Child Benefit started and, if applicable, [Child Benefit stopped](/child-benefit/eligibility)."

    edition[:link] = link
    edition[:introduction] = introduction
    edition[:more_information] = more_information
    edition[:overview] = overview

    edition.save!
    puts "Draft edition created: https://publisher.integration.publishing.service.gov.uk/editions/#{edition.id}"

    UpdateWorker.perform_async(edition.id.to_s)
    puts "Pushing draft to publishing API: https://draft-origin.integration.publishing.service.gov.uk/child-benefit-tax-calculator"
  end
end
