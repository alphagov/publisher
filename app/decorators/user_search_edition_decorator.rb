# Decorator class around editions, to provide user history methods
class UserSearchEditionDecorator
  def initialize(edition, user)
    @edition = edition
    @user = user
  end

  def method_missing(method_name, *args)
    @edition.send method_name, *args
  end

  def user_last_action
    # Note reverse sort
    actions = @edition.actions.sort { |a, b| b.created_at <=> a.created_at }
    last_action = actions.find { |a| [a.requester, a.recipient].include? @user }
    if last_action
      return {
        request_type: last_action.request_type,
        user_role: user_role(last_action),
        summary: summary(last_action),
        timestamp: last_action.created_at
      }
    end
  end

private

  def user_role(action)
    if action.requester == @user && action.recipient == @user
      :both
    elsif action.requester == @user
      :requester
    elsif action.recipient == @user
      :recipient
    end
  end

  # A human-readable summary of an action from the perspective of @user.
  def summary(action)
    human_timestamp = action.created_at.strftime "%d/%m/%Y %H:%M"

    if %w(a e i o u).include? action.request_type[0]
      article = "an"
    else
      article = "a"
    end

    if action.requester == @user
      participle = case action.request_type
                   when Action::CREATE
                     "created"
                   when Action::REQUEST_REVIEW
                     "requested review"
                   when Action::APPROVE_REVIEW
                     "approved review"
                   when Action::APPROVE_FACT_CHECK
                     "approved fact check"
                   when Action::REQUEST_AMENDMENTS
                     "requested amendments"
                   when Action::SEND_FACT_CHECK
                     "sent fact check"
                   when Action::RECEIVE_FACT_CHECK
                     "received fact check"
                   when Action::PUBLISH
                     "published"
                   when Action::ARCHIVE
                     "archived"
                   when Action::NEW_VERSION
                     "made a new version"
                   when Action::NOTE
                     "made a note"
                   when Action::ASSIGN
                     "assigned to #{action.recipient.name}"
                   else
                     "made #{article} '#{action.request_type}' request"
                   end
      participle[0] = participle[0].capitalize
      "#{participle} on #{human_timestamp}"
    elsif action.recipient == @user
      case action.request_type
      when Action::ASSIGN
        "Was assigned by #{action.requester.name} on #{human_timestamp}"
      else
        "Received #{article} '#{action.request_type}' request on #{human_timestamp}"
      end
    end
  end
end
