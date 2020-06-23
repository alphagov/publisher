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
end
