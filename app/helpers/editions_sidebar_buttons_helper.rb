# frozen_string_literal: true

module EditionsSidebarButtonsHelper
  def sidebar_options_heading
    render "govuk_publishing_components/components/heading", {
      text: "Options",
      heading_level: 3,
      font_size: "s",
      padding: true,
    }
  end

  def published_sidebar_buttons(edition)
    buttons = []
    if current_user.has_editor_permissions?(edition)
      buttons << if edition.can_create_new_edition?
                   primary_button_for(edition, duplicate_edition_path(edition), "Create new edition")
                 else
                   link_to("Edit latest edition", edition_path(edition.in_progress_sibling), class: "govuk-link")
                 end
    end
    buttons << link_to(
      "View on GOV.UK (opens in new tab)",
      "#{Plek.website_root}/#{edition.slug}",
      rel: "noreferrer noopener",
      target: "_blank",
      class: "govuk-link",
    )
  end

  def non_published_sidebar_buttons(edition)
    buttons = []
    if current_user.has_editor_permissions?(edition) && !edition.retired_format?
      buttons << (render "govuk_publishing_components/components/button", {
        text: "Save",
        margin_bottom: 3,
      })
    end
    buttons << link_to("Preview (opens in new tab)", preview_edition_path(edition), target: "_blank", rel: "noopener", class: "govuk-link")
  end
end
