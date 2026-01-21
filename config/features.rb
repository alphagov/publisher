Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :default

  if Rails.env.test?
    feature :feature_for_tests,
            default: true,
            description: "A feature only used by tests; not to be used for any actual features."
  end

  feature :design_system_edit_phase_3b,
          default: false,
          description: "Update the publications page to use the GOV.UK Design System with a multi-page design"

  feature :restrict_access_by_org,
          default: true,
          description: "Restrict access to editions based on the user's org and which org(s) own the edition"

  feature :show_link_to_content_block_manager,
          default: %w[integration staging].include?(ENV["GOVUK_ENVIRONMENT"]),
          description: "Shows link to Content Block Manager from Mainstream editor"

  feature :ga4_form_tracking,
          default: false,
          description: "Add tracking to forms across publisher"

  feature :fact_check_manager_api,
          default: false,
          description: "Experimental: enables in-development fact-check-manager API features for testing"

  feature :rename_edition_states,
          default: false,
          description: "Changes the following edition state labels: 'In review' to 'In 2i', 'Fact check'/'Out for fact check' to 'Fact check sent', and 'Scheduled for publishing' to 'Scheduled'"
end
