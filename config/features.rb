Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :default

  if Rails.env.test?
    feature :feature_for_tests,
            default: true,
            description: "A feature only used by tests; not to be used for any actual features."
  end

  feature :design_system_reports_page,
          default: false,
          description: "A transition of the reports page to use the GOV.UK Design System"

  feature :design_system_downtime_new,
          default: false,
          description: "A transition of the add downtime page to use the GOV.UK Design System"

  feature :design_system_downtime_edit,
          default: false,
          description: "A transition of the edit downtime page to the GOV.UK Design System"

  feature :design_system_downtime_index_page,
          default: false,
          description: "A transition of the downtime index page to use the GOV.UK Design System"
end
