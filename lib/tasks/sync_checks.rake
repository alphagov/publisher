require 'sync_checker'

namespace :sync_checks do
  desc "Check editions against their content item in the content store"
  task :check_format, [:format] => :environment do |_, args|
    check_published(args[:format])
    check_draft(args[:format])
  end

  task :check_format_drafts, [:format] => :environment do |_, args|
    check_draft(args[:format])
  end

  def check_published(format)
    puts "Checking live content"
    check_content(format, ['published'], 'content-store')
  end

  def check_draft(format)
    puts "Checking draft content"
    check_content(format, Edition::PUBLISHING_API_DRAFT_STATES, 'draft-content-store')
  end

  def check_content(format, states, store)
    scope = Edition.by_format(format)
    editions = scope.where(state: { '$in' => states })
    checker = SyncChecker.new(editions, store)
    puts "#{editions.count} #{format.titleize} from #{store}"

    checker.add_expectation("schema_name") do |content_item, _|
      content_item["schema_name"] == format
    end

    checker.add_expectation("document_type") do |content_item, edition|
      content_item["document_type"] == format
    end

    checker.add_expectation("title") do |content_item, edition|
      content_item["title"] == edition.title
    end

    checker.add_expectation("public_updated_at") do |content_item, edition|
      content_item_date = DateTime.parse(content_item['public_updated_at'])
      content_item_date.change(usec: 0).utc ==
        (
          edition.public_updated_at ||
          edition.updated_at
        ).change(usec: 0).utc
    end

    checker.call
  end
end
