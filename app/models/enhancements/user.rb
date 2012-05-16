require "user"

class User
  alias_method :record_action_without_noise, :record_action

  def record_action(edition, type, options = {})
    messenger_topic = edition.state.to_s.downcase
    action = record_action_without_noise(edition, type, options)
    Messenger.instance.send messenger_topic, edition unless messenger_topic == "created"
    NoisyWorkflow.make_noise(action).deliver
    NoisyWorkflow.request_fact_check(action).deliver if type.to_s == "send_fact_check"
  end
end
