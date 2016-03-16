namespace :publishing_api do
  task republish_content: [:environment] do
    puts "Scheduling republishing of #{Edition.published.count} editions"

    RepublishContent.schedule_republishing

    puts "Scheduling finished"
  end

  desc "Send publishable item links to Publishing API."
  task publish_all_links: [:environment] do
    def patch_links(item)
      retries = 0
      begin
        payload = EditionLinksPresenter.new(item).payload

        unless payload[:links][:mainstream_browse_pages].empty? && payload[:links][:topics].empty?
          Services.publishing_api.patch_links(item.artefact.content_id, payload)
        end
      rescue GdsApi::TimedOutException, Timeout::Error
        retries = 1
        if retries <= 3
          $stderr.puts "Class #{item.class} id: #{item.id} Timeout: retry #{retries}"
          sleep 0.5
          retry
        end
        raise
      end
    rescue => err
      $stderr.puts "Class: #{item.class}; id: #{item.id}; Error: #{err.message}"
    end

    edition_count = Edition.published.count
    Edition.published.each_with_index do |edition, i|
      patch_links(edition)
      $stdout.puts "Processed #{i}/#{edition_count} published editions" if i % 100 == 0
    end

    $stdout.puts "Finished sending items to Publishing API"
  end
end
