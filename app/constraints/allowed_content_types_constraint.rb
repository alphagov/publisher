class AllowedContentTypesConstraint
  def initialize(allowed_content_types)
    @allowed_content_types = allowed_content_types
  end

  def matches?(request)
    request_path_parameters = "action_dispatch.request.path_parameters"
    if request.env[request_path_parameters] && request.env[request_path_parameters][:id]
      @allowed_content_types.include?(Edition.find(request.env[request_path_parameters][:id]).editionable.class)
    end
  end
end
