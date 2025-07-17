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

  def sidebar_items_list(items)
    render "govuk_publishing_components/components/list", {
      extra_spacing: true,
      items: items,
    }
  end

  def scheduled_for_publishing_sidebar_buttons(edition)
    buttons = []
    if current_user.has_editor_permissions?(edition)
      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Cancel scheduling",
          href: cancel_scheduled_publishing_page_edition_path(edition),
          secondary_solid: true,
          margin_bottom: 3,
        },
      )
      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Publish now",
          href: send_to_publish_page_edition_path(edition),
          secondary_solid: true,
          margin_bottom: 3,
        },
      )
    end
    buttons << link_to(
      "Preview (opens in new tab)",
      preview_edition_path(edition),
      target: "_blank",
      rel: "noopener",
      class: "govuk-link",
    )
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
    if current_user.has_editor_permissions?(edition)
      unless edition.retired_format?
        buttons << (render "govuk_publishing_components/components/button", {
          text: "Save",
          margin_bottom: 3,
        })
      end
      if edition.can_send_fact_check?
        buttons << render(
          "govuk_publishing_components/components/button",
          {
            text: "Fact check",
            href: send_to_fact_check_page_edition_path(edition),
            secondary_solid: true,
            margin_bottom: 3,
          },
        )
      end
      if edition.can_publish?
        if edition.state == "ready"
          buttons << render(
            "govuk_publishing_components/components/button",
            {
              text: "Schedule",
              href: schedule_page_edition_path(edition),
              secondary_solid: true,
              margin_bottom: 3,
            },
          )
        end
        buttons << render(
          "govuk_publishing_components/components/button",
          {
            text: "Publish",
            href: send_to_publish_page_edition_path(edition),
            secondary_solid: true,
            margin_bottom: 3,
          },
        )
      end
    end
    buttons << link_to("Preview (opens in new tab)", preview_edition_path(edition), target: "_blank", rel: "noopener", class: "govuk-link")
    if edition.can_request_review?
      buttons << link_to("Send to 2i", send_to_2i_page_edition_path(edition), class: "govuk-link")
    end

    buttons
  end

  def base_edition_sidebar_buttons(cancel_link_path)
    [
      (render "govuk_publishing_components/components/button", {
        text: "Save",
        margin_bottom: 3,
      }),
      link_to("Cancel", cancel_link_path, class: "govuk-link govuk-link--no-visited-state"),
    ]
  end
end
