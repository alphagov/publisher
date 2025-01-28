module HostContentUpdateHelpers
  def stub_events_for_all_content_ids(action: "HostContentUpdateJob", events: [])
    Services.publishing_api.stubs(:get_events_for_content_id).with(
      regexp_matches(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/),
      {
        action:,
      },
    ).returns(events)
  end
end
