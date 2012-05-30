# This configuration is suitable for development, it should be managed by puppet
# in production.
require 'messenger'

ActionDispatch::Reloader.to_prepare do
  Edition.marples_client_name ||= 'publisher'
  Edition.marples_logger ||= Rails.logger

  if Rails.env.test? or ENV['NO_MESSENGER'].present?
    Messenger.transport ||= Marples::NullTransport.instance
    Edition.marples_transport ||= Marples::NullTransport.instance
  else
    # TODO: Check if this is thread/forked process safe under passenger. Possible risk
    # that client connections get copied when passenger forks a process but the mutexes
    # protecting those connections do not.
    stomp_url = "failover://(stomp://support.cluster:61613,stomp://support.cluster:61613)"
    Messenger.transport ||= Stomp::Client.new stomp_url
    Edition.marples_transport ||= Stomp::Client.new stomp_url
  end
end
