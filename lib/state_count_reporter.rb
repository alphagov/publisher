class StateCountReporter
  def initialize(model_class, states, statsd)
    @model_class = model_class
    @states = states
    @statsd = statsd
  end

  def report
    @statsd.batch do |batch|
      @states.each do |state|
        batch.gauge("state.#{state}", state_count(state))
      end
    end

    nil
  end

private
  def state_count(state)
    @model_class.public_send(state).count
  end
end
