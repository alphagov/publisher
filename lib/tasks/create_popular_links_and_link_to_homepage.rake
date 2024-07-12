desc "Create popular links and links to homepage"
task create_popular_links_and_link_to_homepage: [:environment] do
  homepage_content_id = "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a".freeze
  popular_links = PopularLinksEdition.new(title: "Homepage popular links",
                                          link_items: [{ url: "url1.com", title: "title1" },
                                                       { url: "url2.com", title: "title2" },
                                                       { url: "url3.com", title: "title3" },
                                                       { url: "url4.com", title: "title4" },
                                                       { url: "url5.com", title: "title5" },
                                                       { url: "url6.com", title: "title6" }])

  popular_links.save!

  Services.publishing_api.patch_links(
    homepage_content_id,
    links: {
      "popular_links" => [popular_links.content_id],
    },
  )
rescue StandardError => e
  puts "Encountered error #{e.message}"
end
