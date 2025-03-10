class HostContentUpdateEvent < Data.define(:author, :created_at, :content_id, :content_title, :document_type)
  Author = Data.define(:name, :email)
  def self.all_for_artefact(artefact)
    events = Services.publishing_api.get_events_for_content_id(artefact.content_id, {
      action: "HostContentUpdateJob",
    })

    user_uuids = events.map { |event| event["payload"]["source_block"]["updated_by_user_uid"] }.uniq
    users = users_with_uuids(user_uuids)

    events.map do |event|
      HostContentUpdateEvent.new(
        author: users[event["payload"]["source_block"]["updated_by_user_uid"]],
        created_at: Time.zone.parse(event["created_at"]),
        content_id: event["payload"]["source_block"]["content_id"],
        content_title: event["payload"]["source_block"]["title"],
        document_type: event["payload"]["source_block"]["document_type"],
      )
    end
  end

  def self.users_with_uuids(uuids)
    Services.signon_api.get_users(uuids:).map { |user|
      [user["uid"], Author.new(user["name"], user["email"])]
    }.to_h
  end

  def is_for_edition?(edition)
    if edition.published?
      created_at.after?(edition.published_at)
    elsif edition.archived? && edition.superseded_at && edition.published_at
      created_at.between?(edition.published_at, edition.superseded_at)
    else
      false
    end
  end

  def to_action
    Action.new(self)
  end
end
