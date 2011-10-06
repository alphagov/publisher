# This configuration is suitable for development, it should be managed by puppet
# in production. 
# TODO: Check if this is thread/forked process safe under passenger. Possible risk
# that client connections get copied when passenger forks a process but the mutexes
# protecting those connections do not. 
Messenger.client = Stomp::Client.new('', '', 'localhost', 61613, true)
