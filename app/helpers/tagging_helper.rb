module TaggingHelper
  def tag_summary_rows(type, tagging_update_form_values, linkables, key_text)
    case type
    when "breadcrumb"
      items = breadcrumb(tagging_update_form_values.parent, linkables)
    when "browse_pages"
      items = browse_pages(tagging_update_form_values.mainstream_browse_pages, linkables)
    when "organisations"
      items = organisations(tagging_update_form_values.organisations, linkables)
    when "related_content"
      items = tagging_update_form_values.ordered_related_items
    else
      []
    end

    tag_rows(items, key_text)
  end

  def breadcrumb(parent, linkables)
    get_from_mainstream_browse_pages(parent, linkables)
  end

  def browse_pages(mainstream_browse_pages, linkables)
    get_from_mainstream_browse_pages(mainstream_browse_pages, linkables)
  end

  def organisations(tagged_organisations, linkables)
    linkables.organisations
             .select { |org| tagged_organisations.include? org[1] }
             .map { |org| org[0] }
  end

  def tag_rows(items, key_text)
    items.each_with_index.map do |item, index|
      key = items.count == 1 ? key_text : "#{key_text} #{index + 1}"
      {
        key: key,
        value: item,
      }
    end
  end

  def get_from_mainstream_browse_pages(reference, linkables)
    linkables.mainstream_browse_pages.each_value
             .flat_map do |level_2|
      level_2.select { |page| reference.include? page[1] }
             .map { |page| page[0].gsub(" / ", " > ") }
    end
  end
end
