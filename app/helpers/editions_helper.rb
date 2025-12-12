module EditionsHelper
  EDITION_STATUS_TAG_COLOURS = {
    amends_needed: "red",
    archived: "blue",
    draft: "yellow",
    fact_check: "purple",
    fact_check_received: "pink",
    ready: "green",
    scheduled_for_publishing: "turquoise",
    published: "orange",
    in_review: "grey",
  }.freeze

  # edition transitions are done using fields inlined in the edition form.
  # we need to render activity forms to allow edition transitions on views
  # where the edition form is not present i.e. editions diff view.
  def activity_forms_required?
    params[:action] == "diff"
  end

  def legacy_resource_form(resource, &form_definition)
    html_options = { id: "edition-form" }
    unless resource.locked_for_edits? || resource.archived?
      if resource.editionable.is_a?(Parted)
        html_options["data-module"] = "ajax-save-with-parts"
      elsif resource.format != "SimpleSmartAnswer"
        html_options["data-module"] = "ajax-save"
      end
    end
    nested_form_for resource, as: :edition, url: edition_path(resource), html: html_options, &form_definition
  end

  def legacy_format_conversion_select_options(edition)
    possible_target_formats = Edition.convertible_formats - [edition.artefact.kind]
    possible_target_formats.map { |format_name| [format_name.humanize, format_name] }
  end

  def conversion_items(edition)
    radio_options_hints = {
      "answer" => "One page guidance",
      "completed_transaction" => "Done page for end of a service",
      "guide" => "Multi-page guidance",
      "help_page" => "Info about GOV.UK website, for example Privacy",
      "place" => "Postcode look-up for places/services near you",
      "simple_smart_answer" => "Simple questions and answers that route users to relevant outcomes",
      "transaction" => "Start page for a service",
    }

    possible_target_formats = Edition.convertible_formats - [edition.artefact.kind]
    possible_target_formats.map do |format_name|
      {
        text: format_name.humanize,
        value: format_name,
        hint_text: radio_options_hints[format_name],
      }
    end
  end

  def legacy_format_filter_selection_options
    [%w[All edition]] +
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"].map do |format_name|
        displayed_format_name = format_name.humanize
        displayed_format_name += " (Retired)" if Artefact::RETIRED_FORMATS.include?(format_name)
        [displayed_format_name, format_name]
      end
  end

  def document_summary_items(edition, reviewer)
    reviewer_name = reviewer.nil? ? "Not yet claimed" : reviewer.name

    items = [
      {
        field: "Assigned to",
        value: edition.assigned_to || "None",
        edit: assignee_edit_link(edition),
      },
      {
        field: "Content type",
        value: edition.format.underscore.humanize,
      },
      {
        field: "Edition",
        value: edition_version_and_state_tag(edition),
      },
    ]
    if edition.scheduled_for_publishing?
      items << {
        field: "Scheduled",
        value: edition.publish_at.to_fs(:govuk_date).to_s,
      }
    end
    if edition.in_review?
      items << {
        field: "2i reviewer",
        value: reviewer_name,
        edit: reviewer_edit_link(edition),
      }
    end

    items
  end

  def edition_version_and_state_tag(edition)
    sanitize("#{edition.version_number} <span class='govuk-tag govuk-tag--#{edition.state}'>#{edition.status_text}</span>")
  end

  def administration_authority(edition, administration)
    options = {
      "local_authority_service" => "Service available from local council",
      "devolved_administration_service" => "Service available from devolved administration (or a similar service is available)",
      "unavailable" => "Service not available",
    }
    options[edition.editionable.send("#{administration}_availability").authority_type]
  end

  def edition_status_hint_text(edition)
    case edition.state
    when "fact_check"
      "Sent #{time_ago_in_words(edition.updated_at)} ago"
    when "in_review"
      edition.reviewer.present? ? "2i reviewer: #{edition.reviewer}" : "Not yet claimed"
    when "scheduled_for_publishing"
      "Scheduled for #{edition.publish_at.to_fs(:govuk_date_short)}"
    end
  end

  def edition_status_tag_colour(edition)
    EDITION_STATUS_TAG_COLOURS.fetch(edition.state.to_sym, nil)
  end
end
