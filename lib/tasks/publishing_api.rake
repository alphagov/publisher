namespace :publishing_api do
  desc "republish content"
  task republish_content: [:environment] do
    draft_editions = Edition.draft_in_publishing_api
    editions = Edition.published

    editions.each do |edition|
      RepublishWorker.perform_async(edition.id.to_s)
    end

    draft_editions.each do |draft_edition|
      UpdateWorker.perform_async(draft_edition.id.to_s)
    end
  end

  desc "republish by format"
  task :republish_by_format, [:format] => :environment do |_, args|
    format_editions = Edition.by_format(args[:format])
    editions = format_editions.published
    draft_editions = format_editions.draft_in_publishing_api

    editions.each do |edition|
      RepublishWorker.perform_async(edition.id.to_s)
    end

    draft_editions.each do |draft_edition|
      UpdateWorker.perform_async(draft_edition.id.to_s)
    end
  end

  desc "republish drafts by format"
  task :republish_drafts_by_format, [:format] => :environment do |_, args|
    format_editions = Edition.by_format(args[:format])
    editions = format_editions.draft_in_publishing_api

    editions.each do |draft_edition|
      UpdateWorker.perform_async(draft_edition.id.to_s)
    end
  end

  desc "Publish the experimental knowledge API"
  task publish_knowledge: [:environment] do
    KnowledgeApi.new.publish
  end

  desc "Republish an edition"
  task :republish_edition, %w[slug] => :environment do |_, args|
    editions = Edition.published.where(slug: args[:slug])
    draft_editions = Edition.draft_in_publishing_api.where(slug: args[:slug])

    editions.each do |edition|
      RepublishWorker.perform_async(edition.id.to_s)
    end

    draft_editions.each do |draft_edition|
      UpdateWorker.perform_async(draft_edition.id.to_s)
    end
  end
end
