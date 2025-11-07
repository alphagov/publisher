class AllowedContentTypesConstraint
  def initialize(allowed_content_types)
    @allowed_content_types = allowed_content_types
  end

  def matches?(request)
    request_path_parameters = "action_dispatch.request.path_parameters"
    if request.env[request_path_parameters]
      if request.env[request_path_parameters][:edition_id]
        edition_id = request.env[request_path_parameters][:edition_id]
      elsif request.env[request_path_parameters][:id]
        edition_id = request.env[request_path_parameters][:id]
      else
        return false
      end
      @allowed_content_types.include?(Edition.find(edition_id).editionable.class)
    end
  end
end
