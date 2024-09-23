module TabbedNavHelper
  def edition_nav_items(edition)
    nav_items = []

    all_tab_names.each do |item|
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

  def current_tab_name
    current_tab = (request.path.split("/") & all_tab_names).first
    current_tab == "metadata" ? "metadata" : "temp_nav_text"
  end

private

  def all_tab_names
    %w[edit tagging metadata history admin related_external_links unpublish]
  end
end
