module DowntimesHelper
  def downtime_datetime(downtime)
    start_time = downtime.start_time
    end_time = downtime.end_time
    time_format = "%l:%M%P"
    date_format = "on %e %B"
    datetime_format = "#{time_format} #{date_format}"

    strings = if start_time.to_date == (end_time - 1.second).to_date
                ["#{start_time.strftime(time_format).strip} to #{end_time.strftime(time_format).strip}"] << start_time.strftime(date_format)
              else
                ["#{start_time.strftime(datetime_format).strip} to #{end_time.strftime(datetime_format).strip}"]
              end

    strings.join(" ").gsub(":00", "").gsub("12pm", "midday").gsub("12am", "midnight")
  end

  def transactions_table_entries(transactions)
    transactions.map do |transaction|
      downtime = Downtime.for(transaction.artefact)

      [
        { text: tag.span(transaction.title, class: "downtimes__table-title-column") },
        {
          text: tag.span(downtime ? "Scheduled downtime #{downtime_datetime(downtime)}" : "Live", class: "downtimes__table-state-column"),
        },
        { text: action_link_for_transaction(transaction) },
        { text: link_to("View on website", "#{Plek.website_root}/#{transaction.slug}", class: "govuk-link downtimes__table-link") },
      ]
    end
  end

  def action_link_for_transaction(transaction)
    if transaction.artefact.downtime
      link_to "Edit downtime", edit_edition_downtime_path(transaction), class: "govuk-link downtimes__table-link"
    else
      link_to "Add downtime", new_edition_downtime_path(transaction), class: "govuk-link downtimes__table-link"
    end
  end
end
