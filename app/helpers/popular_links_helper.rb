module PopularLinksHelper
  def popular_link_rows(item)
    rows = []
    rows << { key: "Title", value: item["title"] }
    rows << { key: "URL", value: item["url"] }
    rows.compact
  end
end
