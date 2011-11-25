class ActionController::Base
  before_filter do
    response.headers[Slimmer::SKIP_HEADER] = true
  end
end
