module TabbedNavHelper
  def edition_nav_items(edition, current_user)
    nav_items = []

    accessible_tabs(current_user, edition).each do |item|
      next if !edition.state.eql?("published") && item == "unpublish"

      nav_items << standard_nav_items(item, edition)
    end

    nav_items.flatten
  end

  def current_tab_name
    current_tab = (request.path.split("/") & all_tab_names).first

    case current_tab
    when nil
      "edit"
    when "tagging"
      "tagging"
    when "metadata"
      "metadata"
    when "unpublish"
      "unpublish"
    when "admin"
      "admin"
    when "related_external_links"
      "related_external_links"
    when "history"
      "history"
    else
      "temp_nav_text"
    end
  end

  def assignee_edit_link(edition)
    if current_user.has_editor_permissions?(edition) && can_update_assignee?(edition)
      {
        href: edit_assignee_edition_path(edition),
        link_text: "Edit",
      }
    else
      {}
    end
  end

  def reviewer_edit_link(edition)
    if current_user.has_editor_permissions?(edition)
      {
        href: edit_reviewer_edition_path,
        link_text: "Edit",
      }
    else
      {}
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

  def available_assignee_items(edition)
    items = []
    unless edition.assignee.nil?
      items << { value: edition.assigned_to_id, text: edition.assignee, checked: true }
      items << { value: "none", text: "None", data_attributes: { "ga4-redact-permit": true } }
      items << :or
    end
    User.enabled.order([:name]).each do |user|
      items << { value: user.id, text: user.name } unless user.name == edition.assignee || !user.has_editor_permissions?(edition)
    end
    items
  end

  def available_reviewer_items(edition)
    items = []
    unless edition.reviewer.nil?
      items << { value: edition.reviewer, text: User.where(name: edition.reviewer).first, checked: true }
      items << { value: "none", text: "None" }
      items << :or
    end
    User.enabled.order(name: :asc).each do |user|
      items << { value: user.name, text: user.name } unless user.name.to_s == edition.reviewer || !user.has_editor_permissions?(edition)
    end
    items
  end

  def can_update_assignee?(resource)
    %w[published archived scheduled_for_publishing].exclude?(resource.state)
  end

  def can_update_reviewer?(resource)
    %w[in_review].include?(resource.state)
  end
end
