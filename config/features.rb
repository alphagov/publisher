Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :default

  if Rails.env.test?
    feature :feature_for_tests,
            default: true,
            description: "A feature only used by tests; not to be used for any actual features."
  end

  group "For all users (These features are available to everyone)" do
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

  group "For developer only (These features are for use by developers only)" do
    feature :fact_check_manager_api,
            default: false,
            description: "Experimental: enables in-development fact-check-manager API features for testing"

    feature :guide_chapter_accordion_interface,
            default: true,
            description: "Enable accordion editing interface for guide chapters"
  end
end
