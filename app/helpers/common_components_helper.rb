module CommonComponentsHelper
  def header_for(tab_name)
    render "govuk_publishing_components/components/heading", {
      text: tab_name,
      heading_level: 2,
      margin_bottom: 5,
    }
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
