module PopularLinksHelper
  def popular_link_rows(item)
    rows = []
    rows << { key: "Title", value: item[:title] }
    rows << { key: "URL", value: item[:url] }
    rows.compact
  end

  def primary_button_for(model, url, text)
    form_for model, url:, method: :post do
      render "govuk_publishing_components/components/button", {
        text:,
        margin_bottom: 3,
      }
    end
  end

  def secondary_button_for(model, url, text)
    form_for model, url:, method: :post do
      render "govuk_publishing_components/components/button", {
        text:,
        margin_bottom: 3,
        secondary_solid: true,
      }
    end
  end

  def primary_link_button_for(url, text)
    render "govuk_publishing_components/components/button", {
      text:,
      href: url,
      margin_bottom: 3,
    }
  end
end
