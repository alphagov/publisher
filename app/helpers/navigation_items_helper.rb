module NavigationItemsHelper
  def navigation_items(is_editor: false, user_name: "", path: "")
    list = [
      { text: "My content", href: my_content_path, active: path.end_with?(my_content_path) },
    ]

    if is_editor
      list << { text: "Add artefact", href: new_artefact_path, active: path.end_with?(new_artefact_path) }
      list << { text: "Downtime", href: downtimes_path, active: path.end_with?(downtimes_path) }
    end

    list << { text: "Reports", href: reports_path, active: path.end_with?(reports_path) }
    list << { text: "Search by user", href: user_search_path, active: path.end_with?(user_search_path) }
    list << { text: user_name, href:  Plek.new.external_url_for("signon") } if user_name.present?
    list << { text: "Sign out", href: "/auth/gds/sign_out" }
  end
end
