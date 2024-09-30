module TabbedNavHelper
  def edition_nav_items(edition)
    nav_items = []
    items = %w[edit tagging metadata history admin related_external_links unpublish]

    items.each do |item|
      nav_items << standard_nav_items(item, edition)
    end

    nav_items.flatten
  end

  def standard_nav_items(item, edition)
    url = item.eql?("edit") ? url_for([:edition, { id: edition.id }]) : url_for([:edition, { action: item, id: edition.id }])

    label = Edition::Tab[item].title
    href = url
    current = request.path == url

    edit_nav_item(label, href, current)
  end

  def edit_nav_item(label, href, current)
    [
      {
        label:,
        href:,
        current:,
      },
    ]
  end
end
