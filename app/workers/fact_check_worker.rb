class FactCheckWorker
  include Sidekiq::Worker

  def perform(edition_id, user_id, email_addresses)
    edition = Edition.find(edition_id)
    actor = User.find(user_id)
    FactCheckManagerApiService.request_fact_check(edition, actor, email_addresses)
  end
end
