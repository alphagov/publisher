module PopularLinksHelper
  def popular_link_rows(item)
    rows = []
    rows << { key: "Title", value: item[:title] }
    rows << { key: "URL", value: item[:url] }
    rows.compact
  end

  def button_for(model, url, method, text, secondary_solid: false)
    form_for model, url:, method: do
      render "govuk_publishing_components/components/button", {
        text:,
        margin_bottom: 3,
        secondary_solid:,
      }
    end
  end
end
