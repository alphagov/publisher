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
          default: false,
          description: "Update the publications page to use the GOV.UK Design System"

  feature :design_system_edit,
          default: false,
          description: "Update the publications edit page to use the GOV.UK Design System"

  feature :restrict_access_by_org,
          default: false,
          description: "Restrict access to editions based on the user's org and which org(s) own the edition"
end
