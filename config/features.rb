Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :default

  if Rails.env.test?
    feature :feature_for_tests,
            default: true,
            description: "A feature only used by tests; not to be used for any actual features."
  end

  feature :design_system_publications_filter,
          default: true,
          description: "Update the publications page to use the GOV.UK Design System"

  feature :design_system_edit,
          default: false,
          description: "Update the publications edit page to use the GOV.UK Design System"

  feature :restrict_access_by_org,
          default: true,
          description: "Restrict access to editions based on the user's org and which org(s) own the edition"

  feature :show_link_to_content_block_manager,
          default: %w[integration staging].include?(ENV["GOVUK_ENVIRONMENT"]),
          description: "Shows link to Content Block Manager from Mainstream editor"
end
