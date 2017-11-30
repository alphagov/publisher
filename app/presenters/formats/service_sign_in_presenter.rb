module Formats
  class ServiceSignInPresenter
    def initialize
    end

    def render_for_publishing_api
      {
        schema_name: "service_sign_in",
        rendering_app: "government-frontend",
      }
    end
  end
end
