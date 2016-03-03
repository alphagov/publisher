class PublishingAPINotifier
  include Sidekiq::Worker

  def perform(edition_id, update_type = nil)
    # TODO: Remove this line after it has been deployed.
    if update_type == "normal"
      update_type = nil
    end

    edition = Edition.find(edition_id)
    update_type ||= infer_update_type_from_edition(edition)

    presenter = PublishedEditionPresenter.new(edition)

    Services.publishing_api.put_content(presenter.content_id, presenter.payload)
    Services.publishing_api.publish(presenter.content_id, update_type)
  end

private

  def infer_update_type_from_edition(edition)
    if edition.major_change || edition.version_number == 1
      "major"
    else
      "minor"
    end
  end
end
