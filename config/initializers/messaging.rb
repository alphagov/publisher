# This configuration is suitable for development, it should be managed by puppet
# in production.
# TODO: Check if this is thread/forked process safe under passenger. Possible risk
# that client connections get copied when passenger forks a process but the mutexes
# protecting those connections do not.
require 'messenger'

unless Rails.env.test?
  Publication.marples_client_name = 'publisher'
  Publication.marples_logger = Rails.logger
  stomp_url = "failover://(stomp://support.cluster:61613)"

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Messenger.transport = Stomp::Client.new stomp_url
        Publication.marples_transport = Stomp::Client.new stomp_url
      end
    end
  else
    Messenger.transport = Stomp::Client.new stomp_url
    Publication.marples_transport = Stomp::Client.new stomp_url
  end
end
