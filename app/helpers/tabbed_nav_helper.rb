module TabbedNavHelper
  def edition_nav_items(edition, current_user)
    nav_items = []

    accessible_tabs(current_user, edition).each do |item|
      next if !edition.state.eql?("published") && item == "unpublish"

      nav_items << standard_nav_items(item, edition)
    end

    nav_items.flatten
  end
end

def standard_nav_items(item, edition)
  url = item.eql?("edit") ? url_for([:edition, { id: edition.id }]) : url_for([:edition, { action: item, id: edition.id }])

  label = Edition::Tab[item].title
  href = url
  current = request.path == url

  edit_nav_item(label, href, current)
end

def edit_nav_item(label, href, current)
  [
    {
      label:,
      href:,
      current:,
    },
  ]
end

def current_tab_name
  current_tab = (request.path.split("/") & all_tab_names).first

  case current_tab
  when "metadata"
    "metadata"
  when "unpublish"
    "unpublish"
  when "admin"
    "admin"
  else
    "temp_nav_text"
  end
end

  private

def all_tab_names
  %w[edit tagging metadata history admin related_external_links unpublish]
end

def accessible_tabs(current_user, edition)
  nav_items_to_remove = []
  nav_items_to_remove << "admin" unless current_user.has_editor_permissions?(edition)
  nav_items_to_remove << "unpublish" unless current_user.govuk_editor?

  all_tab_names.reject { |tab| nav_items_to_remove.include?(tab) }
end
