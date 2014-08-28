module EditionActivityHelper
  def edition_activities_fields(f, edition)
    [
      ["Send to Fact check", "send_fact_check"],
      ["Send to 2nd pair of eyes", "request_review"],
      ["Schedule for Publishing", "schedule_for_publishing"],
      ["Cancel Scheduled Publishing", "cancel_scheduled_publishing"],
      ["Send to Publish", "publish"],
    ].map { |args| edition_activity_fields(f, edition, *args) }.join("\n").html_safe
  end

  def edition_activity_fields(f, edition, title, activity)
    check_method = "can_#{activity}?".to_sym

    render(
      :partial => 'shared/edition_activity_fields',
      :locals => {
        :f => f, :title => title, :activity => activity,
        :disabled => !edition.send(check_method)
      }
    )
  end

  def review_forms(edition)
    [
      ["Needs more work",    "request_amendments"],
      ["OK for publication", "approve_review"]
    ].map{ |args| progress_form(edition, *args) }.join("\n").html_safe
  end

  def fact_check_forms(edition)
    [
      ["Needs major changes",    "request_amendments"],
      ["Minor or no changes required", "approve_fact_check"]
    ].map { |args| progress_form(edition, *args) }.join("\n").html_safe
  end

end
