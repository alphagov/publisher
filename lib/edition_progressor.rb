class EditionProgressor
  attr_accessor :edition, :actor, :activity, :statsd, :status_message

  # existing_edition: The existing edition to be duplicated
  # actor:            The WorkflowActor (usually a user) to perform the action
  # statsd:           An object that accepts #decrement and #increment
  def initialize(edition, actor, statsd)
    self.edition = edition
    self.actor   = actor
    self.statsd  = statsd
  end

  # activity: A hash of details about the progress activity to be performed
  #           See test/unit/edition_progressor_test.rb for examples
  def progress(activity)
    action = activity[:request_type]

    ScheduledPublisher.cancel_scheduled_publishing(edition.id.to_s) if action == 'cancel_scheduled_publishing'
    if invalid_fact_check_email_addresses?(activity)
      self.status_message = fact_check_error_message(activity)
      return false
    elsif actor.progress(edition, activity.dup)
      if activity[:request_type] == 'schedule_for_publishing'
        ScheduledPublisher.perform_at(edition.publish_at, actor.id.to_s, edition.id.to_s, activity)
      end
      collect_edition_status_stats(action)
      self.status_message = success_message(action)
      return true
    else
      self.status_message = failure_message(action)
      return false
    end
  end

  protected
    def invalid_fact_check_email_addresses?(activity)
      fact_check_request?(activity[:request_type]) and invalid_email_addresses?(activity[:email_addresses])
    end

    def fact_check_request?(request_type)
      request_type == "send_fact_check"
    end

    def invalid_email_addresses?(addresses)
      addresses.split(",").any? do |address|
        !address.include?("@")
      end
    end

    def collect_edition_status_stats(intended_status)
      statsd.decrement("publisher.edition.#{edition.state}")
      statsd.increment("publisher.edition.#{intended_status}")
    end

    def fact_check_error_message(activity)
      "Couldn't #{activity.to_s.humanize.downcase} for " +
                "#{description(edition).downcase}. The email addresses " +
                "you entered appear to be invalid."
    end

    # TODO: This could probably live in the i18n layer?
    def failure_message(activity)
      case activity
      when 'skip_fact_check' then "Could not skip fact check for this publication."
      when 'start_work' then "Couldn't start work on #{description(edition).downcase}"
      else "Couldn't #{activity.to_s.humanize.downcase} for #{description(edition).downcase}"
      end
    end

    # TODO: This could probably live in the i18n layer?
    def success_message(activity)
      case activity
      when 'start_work' then "Work started on #{description(edition)}"
      when 'skip_fact_check' then "The fact check has been skipped for this publication."
      else "#{description(edition)} updated"
      end
    end

    def description(r)
      r.format.underscore.humanize
    end
end
