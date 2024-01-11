class FeatureConstraint
  def matches?(request)
    request.cookies["design_system_reports_page"] == "1"
  end
end
