module NavigationItemsHelper
  def navigation_items(is_editor: false, user_name: "", path: "")
    [
      { text: "My content", href: my_content_path, active: path.end_with?(my_content_path) },
      { text: "Find content", href: find_content_path, active: path.end_with?(find_content_path) },
      ({ text: new_artefact_link_text, href: new_artefact_path, active: path.end_with?(new_artefact_path) } if is_editor),
      { text: "2i queue", href: two_eye_queue_path, active: path.end_with?(two_eye_queue_path) },
      { text: "Fact check", href: fact_check_path, active: path.end_with?(fact_check_path) },
      ({ text: user_name, href: Plek.new.external_url_for("signon") } if user_name.present?),
      { text: "Sign out", href: "/auth/gds/sign_out" },
    ].compact
  end

private

  def new_artefact_link_text
    Flipflop.enabled?(:design_system_edit_phase_4) ? "Create new content" : "Add artefact"
  end
end
