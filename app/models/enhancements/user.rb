require "user"

class User
  alias_method :record_action_without_noise, :record_action
  alias_method :record_action_without_validation_without_noise, :record_action_without_validation

  def record_action(edition, type, options = {})
    action = record_action_without_noise(edition, type, options)
    NoisyWorkflow.make_noise(action).deliver
    NoisyWorkflow.request_fact_check(action).deliver if type.to_s == "send_fact_check"
  end

  def record_action_without_validation(edition, type, options={})
    action = record_action_without_validation_without_noise(edition, type, options)
    NoisyWorkflow.make_noise(action).deliver
    NoisyWorkflow.request_fact_check(action).deliver if type.to_s == "send_fact_check"
  end
end
