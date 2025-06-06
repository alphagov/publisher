module TaggingHelper
  def breadcrumb(parent, linkables)
    items = []

    linkables.mainstream_browse_pages.each_value do |level_2|
      level_2.each do |page|
        items << page[0].gsub(" / ", " > ") if parent.include? page[1]
      end
    end

    items
  end

  def browse_pages(mainstream_browse_pages, linkables)
    items = []

    linkables.mainstream_browse_pages.each_value do |level_2|
      level_2.each do |page|
        items << page[0].gsub(" / ", " > ") if mainstream_browse_pages.include? page[1]
      end
    end

    items
  end

  def organisations(tagged_organisations, linkables)
    items = []

    linkables.organisations.each do |org|
      items << org[0] if tagged_organisations.include? org[1]
    end

    items
  end

  def related_content(tagged_content)
    items = []

    tagged_content.each do |item|
      items << item["base_path"]
    end

    items
  end

  def tag_summary_rows(items, key_text)
    items.each_with_index.map do |item, index|
      key = items.count == 1 ? key_text : "#{key_text} #{index + 1}"

      {
        key: key,
        value: item,
      }
    end
  end
end
