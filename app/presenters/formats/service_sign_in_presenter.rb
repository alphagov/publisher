module Formats
  class ServiceSignInPresenter
    def initialize
    end

    def render_for_publishing_api
      {
        schema_name: "service_sign_in",
        rendering_app: "government-frontend",
        publishing_app: "publisher",
        document_type: "service_sign_in",
      }
    end
  end
end
