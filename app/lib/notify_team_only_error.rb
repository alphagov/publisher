# Notify rejects emails to recipients outside the GOV.UK Notify team when a
# team-only API key is in use. This should only ever happen outside production.
# It can reach us directly (legacy flow, Publisher sends the email) or as a 502
# from Fact Check Manager, which sends the email on our behalf.
module NotifyTeamOnlyError
  MESSAGE = "One or more recipients are not in the GOV.UK Notify team. This error will not occur in production".freeze
  PATTERN = /team-only API key|not in GOV\.UK Notify team/

  def self.matches?(error)
    return false if GovukEnvironment.current == "production"

    case error
    when Notifications::Client::BadRequestError
      error.message.match?(PATTERN)
    when GdsApi::HTTPErrorResponse
      error.code == 502 && fact_check_manager_notify_error(error).to_s.match?(PATTERN)
    else
      false
    end
  end

  def self.fact_check_manager_notify_error(error)
    details = error.error_details
    details.dig("errors", "notify_error") if details.is_a?(Hash) && details["errors"].is_a?(Hash)
  end
  private_class_method :fact_check_manager_notify_error
end
