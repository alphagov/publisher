require "user"

class User
  alias_method :record_action_without_noise, :record_action
  alias_method :record_action_without_validation_without_noise, :record_action_without_validation

  def record_action(edition, type, options = {})
    action = record_action_without_noise(edition, type, options)
    make_record_action_noises(action, type)
  end

  def record_action_without_validation(edition, type, options={})
    action = record_action_without_validation_without_noise(edition, type, options)
    make_record_action_noises(action, type)
  end

  private
    def make_record_action_noises(action, type)
      NoisyWorkflow.make_noise(action).deliver if type.to_s == "request_review"
      NoisyWorkflow.request_fact_check(action).deliver if type.to_s == "send_fact_check"
    end
end
