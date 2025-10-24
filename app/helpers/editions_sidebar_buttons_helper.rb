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
      class: "govuk-link govuk-link--no-visited-state",
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
      class: "govuk-link govuk-link--no-visited-state",
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
      if edition.can_request_review?
        buttons << link_to("Send to 2i", send_to_2i_page_edition_path(edition), class: "govuk-link govuk-link--no-visited-state")
      end
    end
    buttons << link_to("Preview (opens in new tab)", preview_edition_path(edition), target: "_blank", rel: "noopener", class: "govuk-link govuk-link--no-visited-state")

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

  def guide_add_chapter_sidebar_buttons(edition)
    buttons = []

    if current_user.has_editor_permissions?(edition)
      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Save",
          margin_bottom: 3,
          name: "save",
          value: "save",
        },
      )

      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Save and go to summary",
          margin_bottom: 3,
          secondary_solid: true,
          name: "save",
          value: "save and summary",
        },
      )
      buttons <<
        link_to(
          "Preview (opens in new tab)",
          preview_edition_path(edition),
          target: "_blank",
          rel: "noopener",
          class: "govuk-link govuk-link--no-visited-state",
        )
    end

    buttons
  end

  def history_and_notes_sidebar_buttons(edition)
    buttons = []

    if current_user.has_editor_permissions?(edition)
      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Add edition note",
          margin_bottom: 3,
          href: history_add_edition_note_edition_path,
        },
      )

      buttons << render(
        "govuk_publishing_components/components/button",
        {
          text: "Update important note",
          margin_bottom: 3,
          secondary_solid: true,
          href: history_update_important_note_edition_path,
        },
      )
    end

    buttons << if edition.published? || edition.archived?
                 link_to(
                   "View on GOV.UK (opens in new tab)",
                   "#{Plek.website_root}/#{edition.slug}",
                   rel: "noreferrer noopener",
                   target: "_blank",
                   class: "govuk-link govuk-link--no-visited-state",
                 )
               else
                 link_to(
                   "Preview (opens in new tab)",
                   preview_edition_path(edition),
                   target: "_blank",
                   rel: "noopener",
                   class: "govuk-link govuk-link--no-visited-state",
                 )
               end
    buttons
  end
end
