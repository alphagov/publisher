class HostContentUpdateEvent
  class Action
    CONTENT_BLOCK_UPDATE = "content_block_update".freeze

    attr_reader :host_content_update_event

    def initialize(host_content_update_event)
      @host_content_update_event = host_content_update_event
    end

    def request_type
      CONTENT_BLOCK_UPDATE
    end

    delegate :created_at, to: :host_content_update_event

    def requester
      host_content_update_event.author
    end

    def to_s
      "Content block updated"
    end

    def comment
      "#{humanized_document_type} updated"
    end

    def block_url
      [
        Plek.external_url_for("content-block-manager"),
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

  private

    def humanized_document_type
      host_content_update_event.document_type.delete_prefix("content_block_").humanize
    end
  end
end
