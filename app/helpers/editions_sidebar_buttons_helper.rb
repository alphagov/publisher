# frozen_string_literal: true

module EditionsSidebarButtonsHelper
  def published_sidebar_buttons(edition)
    buttons = []
    buttons << if edition.can_create_new_edition?
                 primary_button_for(edition, duplicate_edition_path(edition), "Create new edition")
               else
                 link_to("Edit latest edition", edition_path(edition.in_progress_sibling), class: "govuk-link")
               end
    buttons << link_to("View on GOV.UK (opens in new tab)", view_homepage_path, rel: "noreferrer noopener", target: "_blank", class: "govuk-link")
  end
end
