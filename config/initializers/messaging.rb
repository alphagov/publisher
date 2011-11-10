# This configuration is suitable for development, it should be managed by puppet
# in production. 
# TODO: Check if this is thread/forked process safe under passenger. Possible risk
# that client connections get copied when passenger forks a process but the mutexes
# protecting those connections do not. 
require 'messenger'

unless Rails.env.test?
  Messenger.transport = Stomp::Client.new "stomp://support.cluster:61613"
  Publication.marples_transport = Stomp::Client.new 'stomp://support.cluster:61613'
end
