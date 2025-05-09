require "action"

module RecordableActions
  extend ActiveSupport::Concern
  included do
    has_many :actions, dependent: :destroy

    def latest_status_action(type = nil)
      if type
        actions.where(request_type: type).last
      else
        most_recent_action(&:status_action?)
      end
    end

    def last_fact_checked_at
      last_fact_check = actions.reverse.find(&:is_fact_check_request?)
      last_fact_check ? last_fact_check.created_at : NullTimestamp.new
    end

    def new_action(user, type, options = {})
      actions.create!(options.merge(requester: user, request_type: type))
    end

    def new_action_without_validation(user, type, options = {})
      action = actions.build(options.merge(requester_id: user.id, request_type: type))
      save!(validate: false)
      action
    end

    def most_recent_action(&blk)
      actions.sort_by(&:created_at).reverse.find(&blk)
    end

    def created_by
      creation = actions.detect do |a|
        [Action::CREATE, Action::NEW_VERSION].include?(a.request_type)
      end
      creation.requester if creation
    end

    def published_by
      latest_action_of_type(Action::PUBLISH)&.requester
    end

    def published_at
      latest_action_of_type(Action::PUBLISH)&.created_at
    end

    def superseded_at
      subsequent_siblings.first&.published_at
    end

  private

    def latest_action_of_type(request_type)
      actions.where(request_type:).first
    end
  end
end
