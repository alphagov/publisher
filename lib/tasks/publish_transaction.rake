require 'gds_api/publishing_api_v2'

namespace :transaction do
  desc "Create a draft transaction for the /part-year-profit-tax-credits start page that previously was in smart-answers"
  task :create_draft, [:base_path] => :environment do |_, args|
    base_path = args[:base_path]
    slug = base_path[1..-1]
    edition = create_transaction(slug)
    raise "edition not found" unless edition
    puts "Populating content"
    edition[:overview] = "Calculate your part-year profits to end your Tax Credits award and claim Universal Credit if you’re self-employed."
    edition[:link] = base_path + "/y"
    edition[:introduction] = "You need to report your part-year profits to end your Tax Credits claim because of a claim to Universal Credit and you’re self-employed.\n\nYou’ll need to know the following to use this calculator: \n- your Tax Credits award end date (you can find this on your award review)\n- your accounting dates for your business\n- your accounting year profit for the tax year in which your tax credits award ends\n\nYou can use this calculator to complete box 2.4 of your award review."
    edition[:change_note] = "Publishing transaction, this is part of switching the start page over from the Smart Answers app so that it looks and behaves the same as every other start page."
    edition.state = "ready"
    edition.save!
    PublishWorker.perform_async(edition.id.to_s, "minor")
    puts "Edition #{base_path} updated"
  end
end

def create_transaction(slug)
  content_id = Services.publishing_api.lookup_content_id(base_path: "/#{slug}")
  title = Services.publishing_api.get_content(content_id).title
  delete_artefacts(slug)
  create_artefact(slug, content_id, title)
  create_edition(slug)
end

def delete_artefacts(slug)
  old_artefacts = Artefact.where(slug: slug)
  unless old_artefacts.empty?
    puts "Deleting existing artefacts to allow creating a new one with path #{slug}"
    old_artefacts.map(&:delete)
  end
end

def create_artefact(slug, content_id, title)
  puts "Creating Artefact existing content_id: #{@content_id}"
  artefact = Artefact.new(
    content_id: content_id,
    slug: slug,
    name: title,
    owning_app: "publisher",
    kind: "transaction",
    state: "draft",
    language: "en"
  )
  artefact.save!
  puts "Artefact saved"
end

def create_edition(slug)
  artefact = Artefact.where(slug: slug, owning_app: "publisher").first
  current_user = User.where(name: "Tatiana Soukiassian").first
  Edition.find_or_create_from_panopticon_data(artefact.id.to_s, current_user)
end
