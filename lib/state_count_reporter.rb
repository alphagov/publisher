class StateCountReporter
  def initialize(model_class, states, statsd)
    @model_class = model_class
    @states = states
    @statsd = statsd
  end

  def report
    @states.each do |state|
      emit(state, state_count(state))
    end

    nil
  end

private
  def state_count(state)
    @model_class.public_send(state).count
  end

  def emit(state, value)
    stat_key = "state.#{state}"
    @statsd.gauge(stat_key, value)
  end
end
