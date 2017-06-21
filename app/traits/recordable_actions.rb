require "action"

module RecordableActions
  extend ActiveSupport::Concern

  included do
    embeds_many :actions

    def latest_status_action(type = nil)
      if type
        self.actions.where(request_type: type).last
      else
        most_recent_action(&:status_action?)
      end
    end

    def last_fact_checked_at
      last_fact_check = actions.reverse.find(&:is_fact_check_request?)
      last_fact_check ? last_fact_check.created_at : NullTimestamp.new
    end

    def new_action(user, type, options = {})
      actions.create!(options.merge(requester_id: user.id, request_type: type))
    end

    def new_action_without_validation(user, type, options = {})
      action = actions.build(options.merge(requester_id: user.id, request_type: type))
      save(validate: false)
      action
    end

    def most_recent_action(&blk)
      self.actions.sort_by(&:created_at).reverse.find(&blk)
    end

    def created_by
      creation = actions.detect do |a|
        a.request_type == Action::CREATE || a.request_type == Action::NEW_VERSION
      end
      creation.requester if creation
    end

    def published_by
      publication = actions.where(request_type: Action::PUBLISH).first
      publication.requester if publication
    end

    def archived_by
      publication = actions.where(request_type: Action::ARCHIVE).first
      publication.requester if publication
    end
  end
end
