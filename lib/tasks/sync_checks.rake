require 'sync_checker'

namespace :sync_checks do
  desc "Check editions against their content item in the content store"
  task check_help_page: [:environment] do
    check_published
    check_draft
  end

  def check_published
    puts "Checking live content"
    check_content(['published'], 'content-store')
  end

  def check_draft
    puts "Checking draft content"
    check_content(Edition::PUBLISHING_API_DRAFT_STATES, 'draft-content-store')
  end

  def check_content(states, store)
    editions = HelpPageEdition.where(state: { '$in' => states })
    checker = SyncChecker.new(editions, store)
    puts "#{editions.count} Help Pages from #{store}"

    checker.add_expectation("schema_name") do |content_item, _|
      content_item["schema_name"] == "help_page"
    end

    checker.add_expectation("document_type") do |content_item, _|
      content_item["document_type"] == "help_page"
    end

    checker.add_expectation("title") do |content_item, edition|
      content_item["title"] == edition.title
    end

    checker.add_expectation("public_updated_at") do |content_item, edition|
      content_item_date = DateTime.parse(content_item['public_updated_at'])
      content_item_date == edition.public_updated_at.to_s
    end

    checker.call
  end
end
