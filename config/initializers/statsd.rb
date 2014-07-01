require "statsd"

# Statsd "the process" listens on a port on the provided host for UDP
# messages. Given that it's UDP, it's fire-and-forget and will not
# block your application. You do not need to have a statsd process
# running locally on your development environment.
statsd_client = Statsd.new("localhost")
statsd_client.namespace = "govuk.app.publisher"

Publisher::Application.statsd = statsd_client
