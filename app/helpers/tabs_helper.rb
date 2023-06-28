module TabsHelper
  # rubocop:disable Rails/HelperInstanceVariable
  def active_tab
    return @active_tab if @active_tab

    visited_tab = request.path.split("/").last
    tab_name = [visited_tab] & %w[metadata tagging history admin related_external_links unpublish]
    @active_tab = tab_name.blank? ? Edition::Tab["edit"] : Edition::Tab[tab_name.first]
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def tab_link(tab, edition_path)
    link_to tab.title,
            tab.path(edition_path),
            "data-target" => "##{tab.name}",
            "data-toggle" => "tab",
            "role" => "tab",
            "aria-controls" => tab.name
  end

  def tabs
    Edition::Tab.all
  end

  def tabs_for(user, resource)
    tabs_to_remove = []
    tabs_to_remove << "admin" unless user.has_editor_permissions?(resource)
    tabs_to_remove << "unpublish" unless user.govuk_editor?
    tabs_to_remove.concat(%w[admin unpublish]) if resource.retired_format?

    tabs.reject { |tab| tabs_to_remove.uniq.include?(tab.name) }
  end
end
