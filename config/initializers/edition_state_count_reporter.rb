require "state_count_reporter"

module Publisher
  class Application
    # We can't simply assign this at initialisation time, because the
    # initialiser for the Statsd client may not have been loaded
    def edition_state_count_reporter
      @edition_state_count_reporter ||= StateCountReporter.new(
        Edition,
        Edition.state_names,
        Publisher::Application.statsd,
      )
    end
  end
end
