GovukAdminTemplate.configure do |c|
  c.app_title = "GOV.UK Publisher"
  c.show_signout = true
end

GovukAdminTemplate.environment_label = ENV.fetch("GOVUK_ENVIRONMENT", "development").titleize
GovukAdminTemplate.environment_style = ENV["GOVUK_ENVIRONMENT"] == "production" ? "production" : "preview"
