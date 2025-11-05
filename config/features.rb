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

  feature :design_system_edit_phase_2,
          default: true,
          description: "Update the publications edit page for Place, Transaction, Local Transaction and Completed Transaction content types to use the GOV.UK Design System"

  feature :design_system_edit_phase_3a,
          default: false,
          description: "Update the publications edit page for Guide content type to use the GOV.UK Design System"

  feature :restrict_access_by_org,
          default: true,
          description: "Restrict access to editions based on the user's org and which org(s) own the edition"

  feature :show_link_to_content_block_manager,
          default: %w[integration staging].include?(ENV["GOVUK_ENVIRONMENT"]),
          description: "Shows link to Content Block Manager from Mainstream editor"

  feature :ga4_form_tracking,
          default: false,
          description: "Add tracking to forms across publisher"
end
