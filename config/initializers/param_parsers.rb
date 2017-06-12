# Turn off XML parsing:
# https://groups.google.com/forum/#!topic/rubyonrails-security/61bkgvnSGTQ/discussion
ActionDispatch::Request::DEFAULT_PARSERS.delete(Mime[:xml])
ActionDispatch::Request::DEFAULT_PARSERS.delete(Mime[:json])
