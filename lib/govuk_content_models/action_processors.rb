Dir[File.join(File.dirname(__FILE__), 'action_processors', '*.rb')].each { |f| require f }

module GovukContentModels
  module ActionProcessors
    REQUEST_TYPE_TO_PROCESSOR = {
      assign: 'AssignProcessor',
      create: 'CreateEditionProcessor',
      request_review: 'RequestReviewProcessor',
      approve_review: 'ApproveReviewProcessor',
      send_fact_check: 'SendFactCheckProcessor',
      resend_fact_check: 'ResendFactCheckProcessor',
      receive_fact_check: 'ReceiveFactCheckProcessor',
      approve_fact_check: 'ApproveFactCheckProcessor',
      skip_fact_check: 'SkipFactCheckProcessor',
      request_amendments: 'RequestAmendmentsProcessor',
      schedule_for_publishing: 'ScheduleForPublishingProcessor',
      cancel_scheduled_publishing: 'CancelScheduledPublishingProcessor',
      publish: 'PublishProcessor',
      archive: 'ArchiveProcessor',
      new_version: 'NewVersionProcessor',
      skip_review: 'SkipReviewProcessor',
    }.freeze
  end
end
