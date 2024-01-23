class FeatureConstraint
  def initialize(feature_name)
    @feature_name = feature_name
  end
  def matches?(request)
    Flipper.enabled?(@feature_name.to_sym)
    # if request.cookies.key?(@feature_name)
    #   request.cookies[@feature_name] == "1"
    # else
    #   Flipper.enabled?(@feature_name.to_sym)
    # end
  end
end