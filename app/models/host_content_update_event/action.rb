class HostContentUpdateEvent
  class Action
    REQUEST_TYPE = "content_block_updated".freeze

    attr_reader :host_content_update_event

    def initialize(host_content_update_event)
      @host_content_update_event = host_content_update_event
    end

    def request_type
      REQUEST_TYPE
    end

    delegate :created_at, to: :host_content_update_event

    def requester
      host_content_update_event.author
    end

    def to_s
      "Content block updated"
    end

    def comment
      "#{host_content_update_event.document_type} updated"
    end

    def block_url
      [
        Plek.external_url_for("whitehall-admin"),
        "content-block-manager",
        "content-block",
        "content-id",
        host_content_update_event.content_id,
      ].join("/")
    end

    def comment_sanitized
      false
    end

    def is_fact_check_request?
      false
    end

    def recipient_id
      nil
    end
  end
end
