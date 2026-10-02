Flipflop.configure do
  # Strategies will be used in the order listed here.

  # Pins fact_check_manager_api on so /flipflop cannot switch a user back to the legacy flow.
  strategy :fact_check_manager_launched,
           description: "Pins the fact check manager journey on for every user." do |feature|
    true if feature == :fact_check_manager_api
  end

  strategy :cookie
  strategy :default

  if Rails.env.test?
    feature :feature_for_tests,
            default: true,
            description: "A feature only used by tests; not to be used for any actual features."
  end

  group "For all users (These features are available to everyone)" do
    feature :show_link_to_content_block_manager,
            default: %w[integration staging].include?(ENV["GOVUK_ENVIRONMENT"]),
            description: "Shows link to Content Block Manager from Mainstream editor"
  end

  group "For developer only (These features are for use by developers only)" do
    feature :fact_check_manager_api,
            default: true,
            description: "Sends fact check requests through fact-check-manager instead of email. Pinned on"
  end
end
